# Group Policy Mass Import
This repository simplifies the process of importing Group Policy Objects (GPO) from one Active Directory forest to another.

> Tested on Microsoft Active Directory 2016.

## JSON Configuration
- The script uses a JSON configuration file for managing GPO imports.
- Example JSON structure:
```json
{
    "admx": "",
    "importable": true,
    "domain": "rsto.ir",
    "description": "Configures Group Policy for security settings.",
    "actions": ["Enable firewall", "Set password policy"],
    "recommended": true,
    "deprecated": false
}
```
### Key Parameters:
- **admx**: Not Implemented yet.
- **importable**: If set to false, the policy will not be imported.
- **domain**: Specifies the target domain for the import. empty string mean import to every domain.
- **description**: Provides details about the policy.
- **actions**: Lists specific actions the policy enforces.
- **recommended**: Not Implemented yet.
- **deprecated**: Not Implemented yet.

### Environment Variable
Before running the script, ensure the environment variable is set:
```
DOMAINNAME = 'your domain'
```

## Ho to import backup in mass
- Add the JSON-formatted configuration to your GPO objects in the Comment section.
- Export GPO backups using the gpmc.msc console.
- Create a folder named Backup and move all GPO backup files into it.
- Run the import script:
```shell
powershell .\Import.ps1
```

This will process the JSON configuration and import the GPOs accordingly.