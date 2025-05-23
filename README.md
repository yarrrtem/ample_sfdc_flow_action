# AmpleFlowEnrichAndSequence

This Salesforce Apex class provides a single Flow Action to:
- Enrich a Contact or Lead using Amplemarket's API ([GET /people/find](https://docs.amplemarket.com/api-reference/people-enrichment/single-person-enrichment))
- Add the Contact or Lead to an Amplemarket sequence ([POST /sequences/{id}/leads](https://docs.amplemarket.com/api-reference/sequences/add-leads))

## How to Use

1. **Install the package in your Salesforce org.**
2. **Create a Record-Triggered Flow on Contact or Lead.**
3. **Add the "AmpleFlowEnrichAndSequence" Apex Action to your Flow.**
4. **Map the following input variables:**
   - `email` (String): Email address of the person to enrich and sequence
   - `amplemarketApiKey` (String): Amplemarket API key
   - `sequenceId` (Amplemarket sequence Id)
   - (Optional) Boolean flags for duplicate/exclusion/recency handling which default to false
5. **Deploy and activate your Flow.**

## What It Does
- Takes an email address directly (no Contact/Lead lookup needed)
- Calls Amplemarket to enrich the record
- Adds the record to the specified Amplemarket sequence

Note: This action does not save any state or data back to Salesforce. It only performs the enrichment and sequencing operations through the Amplemarket API.
## Inputs
- `email` (String): Email address of the person to enrich and sequence
- `amplemarketApiKey` (String): Amplemarket API key
- `sequenceId` (String): Amplemarket sequence Id
- `ignore_recently_contacted` (Boolean, optional): Skip recently contacted check
- `ignore_exclusion_list` (Boolean, optional): Skip exclusion list check  
- `ignore_duplicate_draft` (Boolean, optional): Skip duplicate check in draft sequences
- `ignore_duplicate_active` (Boolean, optional): Skip duplicate check in active sequences

## Outputs
- `success` (Boolean): True if enrichment and sequencing succeeded
- `message` (String): Details or error message