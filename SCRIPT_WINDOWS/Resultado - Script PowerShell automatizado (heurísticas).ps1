PS C:\Users\Elrond Peredhel> Get-ScheduledTask | Where-Object {
>>     ($_.Actions | ForEach-Object { "$($_.Execute) $($_.Arguments)" } -join " ") -match "(?i)\\temp\\|AppData\\|%temp%|Users\\.*\\AppData"
>> } | Select-Object TaskName, TaskPath, @{N='Actions';E={ ($_.Actions | ForEach-Object {"$($_.Execute) $($_.Arguments)"}) -join "; "}} | Format-Table -AutoSize^C
PS C:\Users\Elrond Peredhel> ^C
PS C:\Users\Elrond Peredhel> ^C
PS C:\Users\Elrond Peredhel> # Script de detecção rápida de tarefas agendadas suspeitas
PS C:\Users\Elrond Peredhel> $badPathPatterns = @("(?i)\\AppData\\", "(?i)\\Temp\\", "(?i)%temp%", "(?i)\\Downloads\\")
PS C:\Users\Elrond Peredhel> $badNamePatterns = "(?i)update|updater|svchost|security|windowsupdate|upgrade|installer|audiodriver|taskhost"
PS C:\Users\Elrond Peredhel> $out = @()
PS C:\Users\Elrond Peredhel>
PS C:\Users\Elrond Peredhel> Get-ScheduledTask | ForEach-Object {
>>     $task = $_
>>     $actions = ($task.Actions | ForEach-Object { "$($_.Execute) $($_.Arguments)" }) -join " ; "
>>     $triggers = ($task.Triggers | ForEach-Object { $_.TriggerType }) -join ","
>>     $runLevel = $task.Principal.RunLevel
>>     $hidden = $task.Settings.Hidden
>>     $suspicious = $false
>>     $reasons = @()
>>
>>     # Heurísticas
>>     if ($actions -match $badPathPatterns -or $actions -match "(?i)\\Users\\.*\\AppData") {
>>         $suspicious = $true; $reasons += "Executes from user/temp path"
>>     }
>>     if ($actions -match "(?i)-EncodedCommand|-e\b") {
>>         $suspicious = $true; $reasons += "Encoded PowerShell command"
>>     }
>>     if ($actions -match "(?i)bitsadmin|rundll32|wscript|cscript|mshta|regsvr32") {
>>         $suspicious = $true; $reasons += "Uso de utilitários frequentemente abusados"
>>     }
>>     if ($runLevel -eq "Highest") {
>>         $suspicious = $true; $reasons += "Executa com privilégios elevados"
>>     }
>>     if ($hidden) {
>>         $suspicious = $true; $reasons += "Task oculta"
>>     }
>>     if ($task.TaskName -match $badNamePatterns -and $task.TaskPath -notmatch "Microsoft") {
>>         $suspicious = $true; $reasons += "Nome parecido com sistema mas não é Microsoft"
>>     }
>>     if ($triggers -match "Logon|OnStartup") {
>>         # logon/startup por si só não é mal, mas é um indicador quando combinado com outros
>>         if ($suspicious) { $reasons += "Dispara em logon/startup" }
>>     }
>>
>>     $out += [PSCustomObject]@{
>>         TaskName   = $task.TaskName
>>         TaskPath   = $task.TaskPath
>>         Actions    = $actions
>>         Triggers   = $triggers
>>         RunLevel   = $runLevel
>>         Hidden     = $hidden
>>         Suspicious = $suspicious
>>         Reasons    = ($reasons -join "; ")
>>     }
>> }
PS C:\Users\Elrond Peredhel>
PS C:\Users\Elrond Peredhel> $out | Where-Object { $_.Suspicious -eq $true } | Sort-Object TaskPath, TaskName | Format-Table -AutoSize

TaskName                                      TaskPath                                                    Actions
--------                                      --------                                                    -------
EasyTune                                      \                                                           "C:\Pr...
EasyTune 1                                    \                                                           "C:\Pr...
GraphicsCardEngine                            \                                                           "C:\Pr...
SIV                                           \                                                           "C:\Pr...
SIV-VGA                                       \                                                           "C:\Pr...
.NET Framework NGEN v4.0.30319                \Microsoft\Windows\.NET Framework\
.NET Framework NGEN v4.0.30319 64             \Microsoft\Windows\.NET Framework\
.NET Framework NGEN v4.0.30319 64 Critical    \Microsoft\Windows\.NET Framework\
.NET Framework NGEN v4.0.30319 Critical       \Microsoft\Windows\.NET Framework\
PcaPatchDbTask                                \Microsoft\Windows\Application Experience\                  %windi...
StartupAppTask                                \Microsoft\Windows\Application Experience\                  %windi...
CleanupTemporaryState                         \Microsoft\Windows\ApplicationData\                         %windi...
Pre-staged app cleanup                        \Microsoft\Windows\AppxDeploymentClient\                    %windi...
UCPD velocity                                 \Microsoft\Windows\AppxDeploymentClient\                    %windi...
Proxy                                         \Microsoft\Windows\Autochk\                                 %windi...
BgTaskRegistrationMaintenanceTask             \Microsoft\Windows\BrokerInfrastructure\
maintenancetasks                              \Microsoft\Windows\capabilityaccessmanager\                 %windi...
SyspartRepair                                 \Microsoft\Windows\Chkdsk\                                  %windi...
License Validation                            \Microsoft\Windows\Clip\                                    %Syste...
LicenseImdsIntegration                        \Microsoft\Windows\Clip\                                    %Syste...
CreateObjectTask                              \Microsoft\Windows\CloudExperienceHost\
UnifiedConsentSyncTask                        \Microsoft\Windows\ConsentUX\UnifiedConsent\
CmCleanup                                     \Microsoft\Windows\Containers\
UsbCeip                                       \Microsoft\Windows\Customer Experience Improvement Program\
Data Integrity Check And Scan                 \Microsoft\Windows\Data Integrity Scan\
Data Integrity Scan                           \Microsoft\Windows\Data Integrity Scan\
Data Integrity Scan for Crash Recovery        \Microsoft\Windows\Data Integrity Scan\
ScheduledDefrag                               \Microsoft\Windows\Defrag\                                  %windi...
Driver Recovery on Reboot                     \Microsoft\Windows\Device Setup\
Metadata Refresh                              \Microsoft\Windows\Device Setup\
HandleCommand                                 \Microsoft\Windows\DeviceDirectoryClient\
HandleWnsCommand                              \Microsoft\Windows\DeviceDirectoryClient\
IntegrityCheck                                \Microsoft\Windows\DeviceDirectoryClient\
LocateCommandUserSession                      \Microsoft\Windows\DeviceDirectoryClient\
RegisterDeviceAccountChange                   \Microsoft\Windows\DeviceDirectoryClient\
RegisterDeviceLocationRightsChange            \Microsoft\Windows\DeviceDirectoryClient\
RegisterDevicePeriodic24                      \Microsoft\Windows\DeviceDirectoryClient\
RegisterDevicePolicyChange                    \Microsoft\Windows\DeviceDirectoryClient\
RegisterDeviceProtectionStateChanged          \Microsoft\Windows\DeviceDirectoryClient\
RegisterDeviceSettingChange                   \Microsoft\Windows\DeviceDirectoryClient\
RegisterDeviceWnsFallback                     \Microsoft\Windows\DeviceDirectoryClient\
RegisterUserDevice                            \Microsoft\Windows\DeviceDirectoryClient\
RecommendedTroubleshootingScanner             \Microsoft\Windows\Diagnosis\
Scheduled                                     \Microsoft\Windows\Diagnosis\
UnexpectedCodepath                            \Microsoft\Windows\Diagnosis\                               %windi...
DirectXDatabaseUpdater                        \Microsoft\Windows\DirectX\                                 %windi...
DXGIAdapterCache                              \Microsoft\Windows\DirectX\                                 %windi...
SilentCleanup                                 \Microsoft\Windows\DiskCleanup\                             %windi...
Microsoft-Windows-DiskDiagnosticDataCollector \Microsoft\Windows\DiskDiagnostic\                          %windi...
Microsoft-Windows-DiskDiagnosticResolver      \Microsoft\Windows\DiskDiagnostic\                          %windi...
Diagnostics                                   \Microsoft\Windows\DiskFootprint\                           %windi...
StorageSense                                  \Microsoft\Windows\DiskFootprint\
DmClient                                      \Microsoft\Windows\Feedback\Siuf\                           %windi...
DmClientOnScenarioDownload                    \Microsoft\Windows\Feedback\Siuf\                           %windi...
Property Definition Sync                      \Microsoft\Windows\File Classification Infrastructure\
FODCleanupTask                                \Microsoft\Windows\HelloFace\                               %WinDi...
Monitoring                                    \Microsoft\Windows\Hotpatch\                                %syste...
LocalUserSyncDataAvailable                    \Microsoft\Windows\input\
MouseSyncDataAvailable                        \Microsoft\Windows\input\
PenSyncDataAvailable                          \Microsoft\Windows\input\
RemoteMouseSyncDataAvailable                  \Microsoft\Windows\input\
RemotePenSyncDataAvailable                    \Microsoft\Windows\input\
RemoteTouchpadSyncDataAvailable               \Microsoft\Windows\input\
syncpensettings                               \Microsoft\Windows\input\
TouchpadSyncDataAvailable                     \Microsoft\Windows\input\
SmartRetry                                    \Microsoft\Windows\InstallService\
Uninstallation                                \Microsoft\Windows\LanguageComponentsInstaller\
TempSignedLicenseExchange                     \Microsoft\Windows\License Manager\
WinSAT                                        \Microsoft\Windows\Maintenance\
DetectHardwareChange                          \Microsoft\Windows\Management\Autopilot\
RemediateHardwareChange                       \Microsoft\Windows\Management\Autopilot\
Cellular                                      \Microsoft\Windows\Management\Provisioning\                 %windi...
Logon                                         \Microsoft\Windows\Management\Provisioning\                 %windi...
MdmDiagnosticsCleanup                         \Microsoft\Windows\Management\Provisioning\                 %windi...
Retry                                         \Microsoft\Windows\Management\Provisioning\                 %windi...
RunOnReboot                                   \Microsoft\Windows\Management\Provisioning\                 %windi...
MapsToastTask                                 \Microsoft\Windows\Maps\
AutomaticOfflineMemoryDiagnostic              \Microsoft\Windows\MemoryDiagnostic\
ProcessMemoryDiagnosticEvents                 \Microsoft\Windows\MemoryDiagnostic\
RunFullMemoryDiagnostic                       \Microsoft\Windows\MemoryDiagnostic\
LPRemove                                      \Microsoft\Windows\MUI\                                     %windi...
WiFiTask                                      \Microsoft\Windows\NlaSvc\                                  %Syste...
PCR Prediction Framework Firmware Update Task \Microsoft\Windows\PCRPF\                                   %windi...
RequestTrace                                  \Microsoft\Windows\PerformanceTrace\
WhesvcToast                                   \Microsoft\Windows\PerformanceTrace\
Device Install Group Policy                   \Microsoft\Windows\Plug and Play\
Device Install Reboot Required                \Microsoft\Windows\Plug and Play\
PrinterCleanupTask                            \Microsoft\Windows\Printing\
PrintJobCleanupTask                           \Microsoft\Windows\Printing\
LoginCheck                                    \Microsoft\Windows\PushToInstall\                           %windi...
Registration                                  \Microsoft\Windows\PushToInstall\                           %windi...
VerifyWinRE                                   \Microsoft\Windows\RecoveryEnvironment\
Initialization                                \Microsoft\Windows\ReFsDedupSvc\
RegIdleBackup                                 \Microsoft\Windows\Registry\
RemoteAssistanceTask                          \Microsoft\Windows\RemoteAssistance\                        %windi...
CleanupOfflineContent                         \Microsoft\Windows\RetailDemo\
StartComponentCleanup                         \Microsoft\Windows\Servicing\
Account Cleanup                               \Microsoft\Windows\SharedPC\
CreateObjectTask                              \Microsoft\Windows\Shell\
FamilySafetyMonitor                           \Microsoft\Windows\Shell\                                   %windi...
FamilySafetyRefreshTask                       \Microsoft\Windows\Shell\
ThemeAssetTask_SyncFODState                   \Microsoft\Windows\Shell\
SvcRestartTask                                \Microsoft\Windows\SoftwareProtectionPlatform\
SvcRestartTaskLogon                           \Microsoft\Windows\SoftwareProtectionPlatform\
SvcRestartTaskNetwork                         \Microsoft\Windows\SoftwareProtectionPlatform\
SpaceAgentTask                                \Microsoft\Windows\SpacePort\                               %windi...
SpaceManagerTask                              \Microsoft\Windows\SpacePort\                               %windi...
MaintenanceTasks                              \Microsoft\Windows\StateRepository\                         %windi...
Storage Tiers Management Initialization       \Microsoft\Windows\Storage Tiers Management\
Storage Tiers Optimization                    \Microsoft\Windows\Storage Tiers Management\                %windi...
EnableLicenseAcquisition                      \Microsoft\Windows\Subscription\                            %Syste...
LicenseAcquisition                            \Microsoft\Windows\Subscription\                            %Syste...
PowerGridForecastTask                         \Microsoft\Windows\Sustainability\
SustainabilityTelemetry                       \Microsoft\Windows\Sustainability\
HybridDriveCachePrepopulate                   \Microsoft\Windows\Sysmain\
HybridDriveCacheRebalance                     \Microsoft\Windows\Sysmain\
ResPriStaticDbSync                            \Microsoft\Windows\Sysmain\
WsSwapAssessmentTask                          \Microsoft\Windows\Sysmain\                                 %windi...
Interactive                                   \Microsoft\Windows\Task Manager\
MsCtfMonitor                                  \Microsoft\Windows\TextServicesFramework\
ForceSynchronizeTime                          \Microsoft\Windows\Time Synchronization\
SynchronizeTime                               \Microsoft\Windows\Time Synchronization\                    %windi...
SynchronizeTimeZone                           \Microsoft\Windows\Time Zone\                               %windi...
RunUpdateNotificationMgr                      \Microsoft\Windows\UNP\                                     %windi...
UsageAndQualityInsights-MaintenanceTask       \Microsoft\Windows\UsageAndQualityInsights\                 C:\Win...
Usb-Notifications                             \Microsoft\Windows\USB\
WiFiTask                                      \Microsoft\Windows\WCM\                                     %Syste...
ResolutionHost                                \Microsoft\Windows\WDI\
QueueReporting                                \Microsoft\Windows\Windows Error Reporting\                 %windi...
BfeOnServiceStartTypeChange                   \Microsoft\Windows\Windows Filtering Platform\              %windi...
AutomaticBackup                               \Microsoft\Windows\WindowsBackup\                           %syste...
Windows Backup Monitor                        \Microsoft\Windows\WindowsBackup\                           %syste...
PLUGScheduler                                 \Microsoft\Windows\WindowsUpdate\RUXIM\                     "%Prog...
CDSSync                                       \Microsoft\Windows\WlanSvc\
MoProfileManagement                           \Microsoft\Windows\WlanSvc\
Automatic-Device-Join                         \Microsoft\Windows\Workplace Join\                          %Syste...
Recovery-Check                                \Microsoft\Windows\Workplace Join\                          %Syste...
NotificationTask                              \Microsoft\Windows\WwanSvc\                                 %Syste...
OobeDiscovery                                 \Microsoft\Windows\WwanSvc\


PS C:\Users\Elrond Peredhel>