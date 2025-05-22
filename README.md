# Salesforce DX Project: Next Steps

Now that you've created a Salesforce DX project, what's next? Here are some documentation resources to get you started.

## How Do You Plan to Deploy Your Changes?

Do you want to deploy a set of changes, or create a self-contained application? Choose a [development model](https://developer.salesforce.com/tools/vscode/en/user-guide/development-models).

## Configure Your Salesforce DX Project

The `sfdx-project.json` file contains useful configuration information for your project. See [Salesforce DX Project Configuration](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_ws_config.htm) in the _Salesforce DX Developer Guide_ for details about this file.

## Read All About It

- [Salesforce Extensions Documentation](https://developer.salesforce.com/tools/vscode/)
- [Salesforce CLI Setup Guide](https://developer.salesforce.com/docs/atlas.en-us.sfdx_setup.meta/sfdx_setup/sfdx_setup_intro.htm)
- [Salesforce DX Developer Guide](https://developer.salesforce.com/docs/atlas.en-us.sfdx_dev.meta/sfdx_dev/sfdx_dev_intro.htm)
- [Salesforce CLI Command Reference](https://developer.salesforce.com/docs/atlas.en-us.sfdx_cli_reference.meta/sfdx_cli_reference/cli_reference.htm)

# Amplemarket Flow Action

This package provides a Salesforce Flow Action that enriches Contact data using Amplemarket's API and adds the Contact to an Amplemarket sequence.

## Features

- Enriches Contact data using Amplemarket's `/people/find` endpoint
- Adds Contact to an Amplemarket sequence using `/sequences/{id}/leads` endpoint
- Creates a Task on the Contact summarizing the operation
- Configurable options for handling duplicates and exclusions

## Installation

1. Install the package in your Salesforce org
2. Configure the Flow as described below

## Flow Setup

1. Create a new Record-Triggered Flow on Contact
2. Set trigger conditions:
   - When: A record is created or updated
   - Entry criteria: Email is not null
   - (Optional) Add condition: Do_Not_Enrich__c is not true

3. Add the "Amplemarket: Enrich & Add to Sequence" action
4. Configure the action inputs:
   - contactId: $Record.Id
   - apiKey: Create a Flow variable to store your Amplemarket API key
   - sequenceId: Create a Flow variable to store your target sequence ID
   - ignore_recently_contacted: true (default)
   - ignore_exclusion_list: true (default)
   - ignore_duplicate_draft: true (default)
   - ignore_duplicate_active: true (default)

5. Configure the fault path to handle errors (e.g., send email or create error Task)

## Security Considerations

- Store the Amplemarket API key in a secure location
- Consider using a Named Credential for the API key
- Review and adjust the ignore_* settings based on your requirements

## Testing

The package includes test classes that verify:
- Happy path: Successful enrichment and sequence addition
- Error handling: 404 responses from the API

## Support

For issues or questions, please contact your Salesforce administrator or Amplemarket support.
