#!/usr/bin/env bash
# This script:
# - takes the name of the customer to demo for as first parameter
# - if provided a second parameter (issue number), goes in non-interactive mode

# In non-interactive mode:
# - creates a feature branch with name of customer
# - commits the feature code changes
# - comments on the provided issue how to create a pull request

# Required environment variables for non-interactive mode
# - OCTO_ORG: organization that holds the octocat generator repository
# - OCTO_REPO: octocat generator repo name
# - GITHUB_COM_TOKEN: PAT with write access to the OCTO_REPO
# - GITHUB_APP_TOKEN: GithubAPP Temporary token with admin access to the OCTO_REPO
# - PLATFORM: The Platform label to use
# - THE_CUSTOMER: The Customer this Demo is for

# In interactive mode (one parameter):
# - optionally creates a feature branch if ran on master
# - optionally commits the feature code changes
# - optionally pushes the commits to the same branch upstream

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $DIR/git-setup.sh
BRANCH=$(git branch | sed -n -e 's/^\* \(.*\)/\1/p')

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <customer name> " >&2
  exit 1
fi
CUSTOMER=$1
INTERACTIVE=true

if [ "$#" -gt 1 ]; then
  INTERACTIVE=false
  TRIGGERED_ISSUE=$2
  CUSTOMER=${THE_CUSTOMER}
  git_setup
fi

if [ "$INTERACTIVE" = true ]; then
  if [ $BRANCH == "master" ]
  then
    echo "Your current branch is master, please first create a feature branch"
    echo "  For example: git checkout -b welcome-customer"
    read -p  "Do you want me to create that for you (y/N)?" -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
      git checkout -b welcome-customer || exit 1
      BRANCH="welcome-customer"
    else
      exit 1
    fi
  fi
else
  # normalize customer name in git branch
  BRANCH=`echo $CUSTOMER | sed 's/[^a-zA-Z0-9_\-]*//g'`
  git checkout -b $BRANCH || exit 1
fi

cp -rf $DIR/resources/* $DIR/../
# Add customer name to welcome sign
sed -i.bak -e "s|Customer|$CUSTOMER|g" assets/images/base-octocat.svg

rm assets/images/base-octocat.svg.bak

COMMIT_CHANGES=false
if [ "$INTERACTIVE" = true ]; then
  read -p  "Do you want to commit the code changes on branch '$BRANCH' (y/N)?" -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]
  then
    COMMIT_CHANGES=true
  fi
else
  COMMIT_CHANGES=true
fi

if [ "$COMMIT_CHANGES" = true ]; then
  git add index.html
  git commit -m "Specific welcome message for $CUSTOMER"
  git add assets/images/base-octocat.svg
  git commit -m "Specific logo for $CUSTOMER"
fi

PUSH_CHANGES=false
if [ "$INTERACTIVE" = true ]; then
  read -p  "Do you want to push the code changes on branch '$BRANCH' (y/N)?" -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]
  then
    PUSH_CHANGES=true
  fi
else
  PUSH_CHANGES=true
fi

if [ "$PUSH_CHANGES" = true ]; then
  git push origin HEAD
fi

if [ "$INTERACTIVE" = false ]; then
  cat <<- EOF > $DIR/issues/code-feature.json
  {
    "body": "Feature branch for ${CUSTOMER} [created](https://github.com/${OCTO_ORG}/${OCTO_REPO}/tree/$BRANCH) :sparkles:!\n
    Deployment Platform is: ${PLATFORM}\n
    In order to create a pull request from the [new branch](https://github.com/${OCTO_ORG}/${OCTO_REPO}/tree/$BRANCH), click [here](https://github.com/${OCTO_ORG}/${OCTO_REPO}/compare/master...${OCTO_ORG}:${BRANCH}?expand=1&title=PR%20for%20customer%20branch%20${BRANCH}&labels=${PLATFORM}).\n
    Good luck for your demo!\n
    ![giphy 2](https://cloud.githubusercontent.com/assets/395397/14451851/3abad496-003f-11e6-9a35-1ba112d981d7.gif)"
  }
EOF

  curl -s -H "Authorization: Token $GITHUB_COM_TOKEN" -H "Accept: application/json" -H "Content-type: application/json" -X POST -d @$DIR/issues/code-feature.json https://api.github.com/repos/${OCTO_ORG}/${OCTO_REPO}/issues/$TRIGGERED_ISSUE/comments
fi

# create custom .github/commands/create-demo-stats.yml file on master
git checkout "master" || exit 1
CUSTOMERLOWERCASE=$(echo "$CUSTOMER"| tr '[:upper:]' '[:lower:]')
sed -i.bak -e 's/^# Begin Org\/User List/# Begin Org\/User List\
      - label: '"$CUSTOMER"'\
        value: '"$CUSTOMERLOWERCASE"'/g' .github/commands/create-demo-stats.yml
cat .github/commands/create-demo-stats.yml
rm .github/commands/create-demo-stats.yml.bak
git add .github/commands/create-demo-stats.yml
git commit -m "Create Demo Stats Slash Command for $CUSTOMER"

# Exit if push to master branch suceeded, otherwise try to disable branch protection
git push origin HEAD && exit 0 || true


# disable branch protection

BRANCHES_STATUS_CODE=$(curl -I -H "Authorization: Token $GITHUB_APP_TOKEN" -H "Accept: application/json" https://api.github.com/repos/${OCTO_ORG}/${OCTO_REPO}/branches/master/protection -s -o /dev/null -w %{http_code})

if [ $BRANCHES_STATUS_CODE -ne "404" ] ; then

    echo "Master is protected: disabling protection"

    # Read required status currently activated on master branch
    CONTEXTS=$(curl -H "Authorization: Token $GITHUB_APP_TOKEN" -H "Accept: application/json" https://api.github.com/repos/${OCTO_ORG}/${OCTO_REPO}/branches/master/protection/required_status_checks/contexts)

    # Remove new lines from $CONTEXTS
    CONTEXTS=$(echo $CONTEXTS|tr -d '\n')

    # Disabling protected branches otherwise force push fails (when available in Enterprise)
    curl -H "Authorization: Token $GITHUB_APP_TOKEN" -H "Accept: application/json" -H "Content-type: application/json" -X DELETE https://api.github.com/repos/${OCTO_ORG}/${OCTO_REPO}/branches/master/protection
fi

git push origin HEAD

# re-enable branch protection

if [ "$BRANCHES_STATUS_CODE" -ne 404 ] ; then

    echo "Re-enabling protected branches as before: $CONTEXTS"

    # Get the new JSON based on the protected.json template and run the re-enable API
    sed -e "s|CONTEXTS_PLACEHOLDER|$CONTEXTS|g" scripts/protected.json | curl -H "Authorization: Token $GITHUB_APP_TOKEN" -H "Accept: application/json" -H "Content-type: application/json" -X PUT https://api.github.com/repos/${OCTO_ORG}/${OCTO_REPO}/branches/master/protection -d @-
fi
