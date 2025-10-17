# Intune Per Setting Device Policy
The idea behind this set of scripts is to solve for trying to track a few major Intune policies and systems that are not compliant with them at a per-setting level.

Intune Graph API provides a nice report export that you can request the user/device processing of a given policy to determine if the system fully applied the settings succesfully or not.  [Link to docs](https://learn.microsoft.com/en-us/intune/intune-service/fundamentals/reports-export-graph-available-reports#devicepoliciescompliancereport)

The idea I had was, why not use obtain a list of system/user errors for the policy; and using those deviceId and userId's together with the policyId in question - query each errored system for the list of configuration items they failed to process.  Depending on your environment size, you may wish to collect everything, but I'm trying to keep this lean and relavent for catching the settings that errored and on which settings.  That can be found of course manually in the portal, but I wanted to make something that I could extend to non admins that they can review in an audit type scenario.  Therefore, the focus of this project is on Errors.

## Issues
- Intune Portal appears to use two (maybe more) api's for showing an instance of a user applying an Intune configuration policy.  Hitting the wrong API for a given policy will produce a zero byte response (a 200 nontheless).
   - getConfigurationSettingNoncomplianceReport: Update Rings, Custom Oma-Uri polcies, 
   - getConfiguratinoSettingsReport: Settings Template Policies
