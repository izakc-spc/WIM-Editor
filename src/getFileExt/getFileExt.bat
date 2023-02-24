set file=%isoSelection%
FOR %%i IN (%file%) DO (
set fileExtension=%%~xi
)
set fileExtension=%fileExtension:o""=o%