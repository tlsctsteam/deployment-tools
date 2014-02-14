:: Script:         deploy.bat
:: Purpose:        Windows SVN deployment script
::
:: Usage:          deploy.bat [trunk | branch-name] [target-environment]
:: Examples:       deploy.bat trunk AVIS-STAGE-CF
::                 deploy.bat RC-13.2.1 AVIS-STAGE-LONDON
::
:: History
:: -----------------------------------------------------------------------------
:: dd.mm.yyyy   Michael Traher   Original version
:: 06.02.2013   Andy Neale       Combined version for all clients
:: 02.08.2013   Andy Neale       Restart ColdFusion instances after deployment
:: 05.09.2013   Andy Neale       Synchronised with latest version of IHG script
:: 23.01.2014   Andy Neale       Removed settings for Avis Europe
::                               Minor updates for additional IHG environments
:: -----------------------------------------------------------------------------


@echo off

echo ::
echo ::
echo ::
echo ::


:: Ensure the right number of parameters has been provided
:: -----------------------------------------------------------------------------

if "%2" equ "" goto error
if "%1" equ "" goto error


:: Ensure the target environment is valid and identify the client system
:: -----------------------------------------------------------------------------


:: GT
:: -----------------------------------------------------------------------------
if "%2" equ "GT-STAGE" (
  set client=GTH
  set source=branches
  set instance1="Adobe ColdFusion 9 AS gt-tls-stage"
  set instance2="Adobe ColdFusion 9 AS gt-ws-stage"
  goto config
)
if "%2" equ "GT-STAGE-CF" (
  set client=GTH
  set source=branches
  set instance1="Adobe ColdFusion 9 AS gt-tls-stage"
  set instance2="Adobe ColdFusion 9 AS gt-ws-stage"
  goto config
)
if "%2" equ "GT-STAGE-LONDON" (
  set client=GTH
  set source=branches
  set instance1="Adobe ColdFusion 9 AS gt-tls-stage"
  set instance2="Adobe ColdFusion 9 AS gt-ws-stage"
  goto config
)
if "%2" equ "GT-STAGE-MUMBAI" (
  set client=GTH
  set source=branches
  set instance1="Adobe ColdFusion 9 AS gt-tls-stage"
  set instance2="Adobe ColdFusion 9 AS gt-ws-stage"
  goto config
)
if "%2" equ "GT-UAT" (
  set client=GTH
  set source=branches
  set instance1="Adobe ColdFusion 9 AS gt-tls-uat"
  set instance2="Adobe ColdFusion 9 AS gt-ws-uat"
  goto config
)
if "%2" equ "GT-PROD" (
  set client=GTH
  set source=tags
  set instance1=""
  set instance2=""
  goto config
)

:: LOREAL
:: -----------------------------------------------------------------------------
if "%2" equ "LOREAL-FT" (
  set client=LOR
  set source=branches
  set instance1="Adobe ColdFusion 9 AS lor-tls-ft"
  set instance2=""
  goto config
)
if "%2" equ "LOREAL-FT-CF" (
  set client=LOR
  set source=branches
  set instance1="Adobe ColdFusion 9 AS lor-tls-ft-cf"
  set instance2=""
  goto config
)
if "%2" equ "LOREAL-FT-LONDON" (
  set client=LOR
  set source=branches
  set instance1="Adobe ColdFusion 9 AS lor-tls-ft-london"
  set instance2=""
  goto config
)
if "%2" equ "LOREAL-FT-MUMBAI" (
  set client=LOR
  set source=branches
  set instance1="Adobe ColdFusion 9 AS lor-tls-ft-mumbai"
  set instance2=""
  goto config
)
if "%2" equ "LOREAL-UAT" (
  set client=LOR
  set source=branches
  set instance1="Adobe ColdFusion 9 AS tls-loreal-uat"
  set instance2="Adobe ColdFusion 9 AS ws-loreal-uat"
  goto config
)
if "%2" equ "LOREAL-PROD" (
  set client=LOR
  set source=tags
  set instance1=""
  set instance2=""
  goto config
)

:: IHG
:: -----------------------------------------------------------------------------
if "%2" equ "IHG-STAGE" (
  set client=IHG
  set source=branches
  set ws_site_code=IHG-WEBSERVICES-STAGE
  set instance1="Adobe ColdFusion 9 AS IHGstage"
  set instance2="Adobe ColdFusion 9 AS IHGwebservices"
  goto config
)
if "%2" equ "IHG-FT" (
  set client=IHG
  set source=branches
  set ws_site_code=IHG-WEBSERVICES-CF
  set instance1="ColdFusion 10 Application Server ihg-tls-ft"
  set instance2="ColdFusion 10 Application Server ihg-ws-ft"
  goto config
)
if "%2" equ "IHG-UAT-SVN" (
  set client=IHG
  set source=branches
  set ws_site_code=IHG-WEBSERVICES-UAT-SVN
  set instance1="Adobe ColdFusion 8 AS IHG_UAT"
  set instance2="Adobe ColdFusion 8 AS IHG_UAT_WS"
  goto config
)
if "%2" equ "IHG-RC" (
  set client=IHG
  set source=branches
  set ws_site_code=IHG-WEBSERVICES-RC
  set instance1="Adobe ColdFusion 9 AS IHG_RC"
  set instance2=""
  goto config
)
if "%2" equ "IHG-PROD" (
  set client=IHG
  set source=tags
  set ws_site_code=IHG-WEBSERVICES-PROD
  set instance1=""
  set instance2=""
  goto config
)
if "%2" equ "IHG-TRAINING" (
  set client=IHG
  set source=tags
  set ws_site_code=IHG-WEBSERVICES-TRAINING
  set instance1="Adobe ColdFusion 8 AS IHG_Train"
  set instance2="Adobe ColdFusion 8 AS IHG_train_WS"
  goto config
)
goto error

:config

:: Set all of the client- and environment-specific variables we need
:: -----------------------------------------------------------------------------

:: Location of SVN repository
set svnurl=https://svn.collinsontech.com/GMS/Projects/

:: Username and Password
set username=TLS.Build
set password=army-m3tro

:: Target environment
set site_code=%2

::  Branch/tag name to be deployed
if "%1" neq "trunk" set svn_folder=%source%/%1
if "%1" equ "trunk" set svn_folder=%1

:: Target directory
if "%source%" equ "tags" (
  set directory=C:\svn_deploy_folders
) else (
  if "%client%" equ "IHG" (
    set directory=E:\wwwroot
    if "%2" equ "IHG-FT" set directory=D:\inetpub\wwwroot
    if "%2" equ "IHG-UAT" set directory=E:\inetpub
    if "%2" equ "IHG-TRAINING" set directory=C:\svn_deploy_folders
  ) else (
    set directory=D:\inetpub\wwwroot
  )
)

:: Webroot
if "%client%" equ "IHG" (
  set webroot=%directory%\%site_code%\Artimis_CORE
  set webrootsite=%directory%\%site_code%\Artimis_SITES_IHG
  set wswebroot=%directory%\%ws_site_code%
) else (
  set webroot=%directory%\%site_code%
)

:: SVN projects
if "%client%" equ "GTH" (
  set core_project=cts-loyalty-core/
  set site_project=gms-loyalty-sites/guoman-thistle/
)
if "%client%" equ "IHG" (
  set core_project=cts-ihg-core/
  set site_project=cts-ihg-sites/
)
if "%client%" equ "LOR" (
  set core_project=cts-loreal-core/
  set site_project=gms-loyalty-sites/loreal/
)
goto process

:process

:: Variables all set, time to do some SVN stuff
:: -----------------------------------------------------------------------------

echo ::
echo :: Deploying ~%svn_folder%~ to %site_code%
echo ::

if exist "%webroot%\CORE\Web_Apps\.svn" goto do_switch else goto do_checkout


:do_checkout

:: SVN checkout if no checkout has been done before
:: -----------------------------------------------------------------------------

echo :: Checking Out...

if "%client%" equ "IHG" (
  if exist "%webroot%\CORE\Web_Apps"   erase /q /s /f %webroot%\CORE\Web_Apps
  if exist "%webroot%\customtags"      erase /q /s /f %webroot%\customtags
  if exist "%webroot%\udfs"            erase /q /s /f %webroot%\udfs
  if exist "%webroot%\Webservices"     erase /q /s /f %webroot%\Webservices
  if exist "%webrootsite%\SITE\root"   erase /q /s /f %webrootsite%\SITE\root
  svn checkout --username %username% --password %password% %svnurl%%core_project%%svn_folder%/CORE/Web_Apps        %webroot%\CORE\Web_Apps
  svn checkout --username %username% --password %password% %svnurl%%core_project%%svn_folder%/customtags           %webroot%\customtags
  svn checkout --username %username% --password %password% %svnurl%%core_project%%svn_folder%/udfs                 %webroot%\udfs
  svn checkout --username %username% --password %password% %svnurl%%core_project%%svn_folder%/WebServices          %webroot%\WebServices
  svn checkout --username %username% --password %password% %svnurl%%site_project%%svn_folder%/SITE/root            %webrootsite%\SITE\root
  if exist "%wswebroot%\customtags"    erase /q /s /f %wswebroot%\customtags
  if exist "%wswebroot%\udfs"          erase /q /s /f %wswebroot%\udfs
  if exist "%wswebroot%\Webservices"   erase /q /s /f %wswebroot%\Webservices
  if exist "%wswebroot%\customcode"    erase /q /s /f %wswebroot%\customcode
  svn checkout --username %username% --password %password% %svnurl%%core_project%%svn_folder%/customtags           %wswebroot%\customtags
  svn checkout --username %username% --password %password% %svnurl%%core_project%%svn_folder%/udfs                 %wswebroot%\udfs
  svn checkout --username %username% --password %password% %svnurl%%core_project%%svn_folder%/WebServices          %wswebroot%\WebServices
  svn checkout --username %username% --password %password% %svnurl%%site_project%%svn_folder%/SITE/root/customcode %wswebroot%\customcode
) else (
  if exist "%webroot%\CORE\Web_Apps"   erase /q /s /f %webroot%\CORE\Web_Apps
  if exist "%webroot%\customtags"      erase /q /s /f %webroot%\customtags
  if "%client%" equ "LOR" (
    if exist "%webroot%\udfs"          erase /q /s /f %webroot%\udfs
  )
  if exist "%webroot%\Webservices"     erase /q /s /f %webroot%\Webservices
  if exist "%webroot%\SITE\root"       erase /q /s /f %webroot%\SITE\root
  svn checkout --username %username% --password %password% %svnurl%%core_project%%svn_folder%/CORE/Web_Apps %webroot%\CORE\Web_Apps
  svn checkout --username %username% --password %password% %svnurl%%core_project%%svn_folder%/customtags    %webroot%\customtags
  if "%client%" equ "LOR" (
    svn checkout --username %username% --password %password% %svnurl%%core_project%%svn_folder%/udfs        %webroot%\udfs
  )
  svn checkout --username %username% --password %password% %svnurl%%core_project%%svn_folder%/WebServices   %webroot%\WebServices
  if "%client%" equ "GTH" (
    svn checkout --username %username% --password %password% %svnurl%%site_project%%svn_folder%/root        %webroot%\SITE
  ) else (
    svn checkout --username %username% --password %password% %svnurl%%site_project%%svn_folder%/root        %webroot%\SITE\root
  )
)
echo :: Checkout complete.
goto restart

:do_switch

:: SVN switch when a previous checkout has been done
:: -----------------------------------------------------------------------------

echo :: Switching...

@echo on

if "%client%" equ "IHG" (
  svn revert --recursive %webroot%\CORE\Web_Apps
  svn revert --recursive %webroot%\customtags
  svn revert --recursive %webroot%\udfs
  svn revert --recursive %webroot%\WebServices
  svn revert --recursive %webrootsite%\SITE\root
  svn switch --username  %username% --password %password% %svnurl%%core_project%%svn_folder%/CORE/Web_Apps        %webroot%\CORE\Web_Apps
  svn switch --username  %username% --password %password% %svnurl%%core_project%%svn_folder%/customtags           %webroot%\customtags
  svn switch --username  %username% --password %password% %svnurl%%core_project%%svn_folder%/udfs                 %webroot%\udfs
  svn switch --username  %username% --password %password% %svnurl%%core_project%%svn_folder%/WebServices          %webroot%\WebServices
  svn switch --username  %username% --password %password% %svnurl%%site_project%%svn_folder%/SITE/root            %webrootsite%\SITE\root
  svn revert --recursive %wswebroot%\customtags
  svn revert --recursive %wswebroot%\udfs
  svn revert --recursive %wswebroot%\WebServices
  svn revert --recursive %wswebroot%\customcode
  svn switch --username  %username% --password %password% %svnurl%%core_project%%svn_folder%/customtags           %wswebroot%\customtags
  svn switch --username  %username% --password %password% %svnurl%%core_project%%svn_folder%/udfs                 %wswebroot%\udfs
  svn switch --username  %username% --password %password% %svnurl%%core_project%%svn_folder%/WebServices          %wswebroot%\WebServices
  svn switch --username  %username% --password %password% %svnurl%%site_project%%svn_folder%/SITE/root/customcode %wswebroot%\customcode
) else (
  svn revert --recursive %webroot%\CORE\Web_Apps
  svn revert --recursive %webroot%\customtags
  if "%client%" equ "LOR" (
    svn revert --recursive %webroot%\udfs
  )
  svn revert --recursive %webroot%\WebServices
  svn revert --recursive %webroot%\SITE\root
  svn switch --username  %username% --password %password% %svnurl%%core_project%%svn_folder%/CORE/Web_Apps %webroot%\CORE\Web_Apps
  svn switch --username  %username% --password %password% %svnurl%%core_project%%svn_folder%/customtags    %webroot%\customtags
  if "%client%" equ "LOR" (
    svn switch --username %username% --password %password% %svnurl%%core_project%%svn_folder%/udfs         %webroot%\udfs
  )
  svn switch --username   %username% --password %password% %svnurl%%core_project%%svn_folder%/WebServices  %webroot%\WebServices
  if "%client%" equ "GTH" (
    svn switch --username %username% --password %password% %svnurl%%site_project%%svn_folder%/root         %webroot%\SITE
  ) else (
    svn switch --username %username% --password %password% %svnurl%%site_project%%svn_folder%/root         %webroot%\SITE\root
  )
)

@echo off
echo :: Switch complete.
goto restart


:error

:: Invalid parameters provided
:: -----------------------------------------------------------------------------

@echo :: Invalid parameters
@echo ::
@echo :: Usage...
@echo :: $ deploy.bat ["trunk" or branch name] [target environment]
@echo :: Examples...
@echo :: $ deploy.bat trunk LOREAL-FT
@echo :: $ deploy.bat RC-13.2.1 AVIS-STAGE-LONDON
@echo ::
goto :eof


:restart

:: Restart services following deployment
:: -----------------------------------------------------------------------------

if "%instance1%" neq "" (
  call stop.cmd %instance1%
  call start.cmd %instance1%
)
if "%instance2%" neq "" (
  call stop.cmd %instance2%
  call start.cmd %instance2%
)
goto end


:end

echo ::
echo :: Completed deployment of %svn_folder% to %site_code
echo ::
pause

:eof
