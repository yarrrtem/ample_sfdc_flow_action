# AmpleFlowEnrichAndSequence

This Salesforce Apex class provides a single Flow Action to:
- Enrich a Contact using Amplemarket's API ([GET /people/find](https://docs.amplemarket.com/api-reference/people-enrichment/single-person-enrichment))
- Add the Contact to an Amplemarket sequence ([POST /sequences/{id}/leads](https://docs.amplemarket.com/api-reference/sequences/add-leads))
- Log the enrichment and sequencing results as a Task on the Contact

## How to Use

1. **Install the package in your Salesforce org.**
2. **Create a Record-Triggered Flow on Contact.**
3. **Add the "AmpleFlowEnrichAndSequence" Apex Action to your Flow.**
4. **Map the following input variables:**
   - `contactId` (`Triggering Contact` > `ContactID`)
   - `apiKey` (Amplemarket API key)
   - `sequenceId` (Amplemarket sequence Id)
   - (Optional) Boolean flags for duplicate/exclusion/recency handling which default to false
5. **Deploy and activate your Flow.**

## What It Does
- Looks up the Contact by Id
- Calls Amplemarket to enrich the Contact
- Adds the Contact to the specified Amplemarket sequence
- Creates a Task on the Contact with a summary of the enrichment and sequencing

## Inputs
- `contactId` (Id): The Contact to enrich and sequence
- `apiKey` (String): Amplemarket API key
- `sequenceId` (String): Amplemarket sequence Id
- `ignore_recently_contacted`, `ignore_exclusion_list`, `ignore_duplicate_draft`, `ignore_duplicate_active` (Boolean, optional): Control Amplemarket sequence behavior

## Outputs
- `success` (Boolean): True if enrichment and sequencing succeeded
- `message` (String): Details or error message