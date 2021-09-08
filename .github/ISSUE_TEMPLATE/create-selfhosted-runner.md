---
name: Create self-hosted runner
about: Create a self-hosted runner you can use for a workflow
title: Create self-hosted runner
labels: 'selfhosted-runner'
assignees: ''
issue_body: true
inputs:
- type: description
  attributes:
    value: So you like to provision a self-hosted runner using IssueOps! Please fill out this form with the machine specifications.
- type: input
  attributes:
    label: What cloud should be used to provision the runner?
    required: true
    text: GCP
- type: input
  attributes:
    label: How big should the machine be sized (small, medium, large)?
    required: true
    placeholder: medium
- type: textarea
  attributes:
    label: Any further provisioning hints?
    required: false
    placeholder: IO/optimized
---
name: Create self-hosted runner
about: Create a self-hosted runner you can use for a workflow
title: Create self-hosted runner
labels: 'selfhosted-runner'
assignees: ''
issue_body: true
inputs:
- type: description
  attributes:
    value: So you like to provision a self-hosted runner using IssueOps! Please fill out this form with the machine specifications.
- type: input
  attributes:
    label: What cloud should be used to provision the runner?
    required: true
    text: GCP
- type: input
  attributes:
    label: How big should the machine be sized (small, medium, large)?
    required: true
    placeholder: medium
- type: textarea
  attributes:
    label: Any further provisioning hints?
    required: false
    placeholder: IO/optimized
