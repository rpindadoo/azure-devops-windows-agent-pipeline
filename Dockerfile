# escape=`
FROM mcr.microsoft.com/dotnet/framework/runtime:4.8

# Restore the default Windows shell for correct batch processing.
SHELL ["cmd", "/S", "/C"]
 
# Download & Install the Visual Studio Build Tools.
ADD https://aka.ms/vs/16/release/vs_BuildTools.exe C:\TEMP\vs_BuildTools.exe
RUN C:\TEMP\vs_BuildTools.exe --quiet --wait --norestart --nocache `
    --add Microsoft.VisualStudio.Workload.DataBuildTools `
    --add Microsoft.VisualStudio.Workload.ManagedDesktopBuildTools `
    --add Microsoft.VisualStudio.Workload.MSBuildTools `
    --add Microsoft.VisualStudio.Workload.NetCoreBuildTools `
    --add Microsoft.VisualStudio.Workload.NodeBuildTools `
    --add Microsoft.VisualStudio.Workload.WebBuildTools `
    --includeRecommended `
    --includeOptional `
    --remove Microsoft.VisualStudio.Component.Windows10SDK.10240 `
    --remove Microsoft.VisualStudio.Component.Windows10SDK.10586 `
    --remove Microsoft.VisualStudio.Component.Windows10SDK.14393 `
    --remove Microsoft.VisualStudio.Component.Windows81SDK `
    || IF "%ERRORLEVEL%"=="3010" EXIT 0;    
 
# Install Agents for Visual Studio
#O TB choco install visualstudio2019testagent --version=16.7.7.0
 ADD https://aka.ms/vs/16/release/vs_TestAgent.exe C:\TEMP\vs_TestAgent.exe
 RUN C:\TEMP\vs_TestAgent.exe --quiet --wait --norestart --nocache || IF "%ERRORLEVEL%"=="3010" EXIT 0;
 
# Install Git
RUN powershell -Command `
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; `
    Invoke-WebRequest -OutFile mingit.zip https://github.com/git-for-windows/git/releases/download/v2.30.0.windows.2/MinGit-2.30.0.2-busybox-64-bit.zip; `
    Expand-Archive mingit.zip -Force -DestinationPath C:\TEMP\git; `
    Move-Item C:\TEMP\git "${Env:ProgramFiles}\git"; `
    Remove-Item mingit.zip -Force; `
    setx /M PATH $($Env:PATH + ';' + ${Env:ProgramFiles} + '\git\cmd');

# Overwrite the default gitconfig file as it has an infinite loop in it - see https://gitlab.com/gitlab-org/gitlab/-/issues/239013#note_400463268
RUN powershell -Command `
$old = Get-Content 'C:\Program Files\git\etc\gitconfig'; `
$new = $old[0..($old.count-2)]; `
Set-Content 'C:\Program Files\git\etc\gitconfig' $new;
 
# Install NodeJS
RUN powershell -Command `
    Invoke-WebRequest -OutFile nodejs.zip https://nodejs.org/download/release/v10.23.1/node-v10.23.1-win-x64.zip; `
    Expand-Archive nodejs.zip -Force -DestinationPath C:\TEMP\nodejs; `
    Move-Item C:\TEMP\nodejs\node-v10.23.1-win-x64 "${Env:ProgramFiles}\nodejs"; `
    Remove-Item nodejs.zip -Force; `
    setx /M PATH $($Env:PATH + ';' + ${Env:ProgramFiles} + '\nodejs');
  
# Install NuGet
RUN powershell -Command `
    mkdir "${Env:ProgramFiles(x86)}\NuGet"; `
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; `
    Invoke-WebRequest -OutFile nuget.exe https://dist.nuget.org/win-x86-commandline/latest/nuget.exe; `
    Move-Item nuget.exe "${Env:ProgramFiles(x86)}\NuGet"; `
    setx /M PATH $($Env:PATH + ';' + ${Env:ProgramFiles(x86)} + '\NuGet');
  


# Download & install Chrome
WORKDIR /
RUN powershell -Command `
    Add-WindowsFeature Web-WebSockets; `
    Set-ExecutionPolicy Bypass -Scope Process -Force; `
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; `
    iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1')); `
    choco install googlechrome -y --version=90.0.4430.212 --ignore-checksums; 

 
WORKDIR /
RUN powershell -Command `
    Add-WindowsFeature Web-WebSockets; `
    Set-ExecutionPolicy Bypass -Scope Process -Force; `
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; `
    iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1')); `
    choco install chromedriver -y; `
    choco install dotnet-5.0-sdk -y;

RUN powershell -Command `
    mkdir .\SeleniumWebDrivers\ChromeDriver\; `
    Copy-Item -Path C:\ProgramData\chocolatey\lib\chromedriver\tools\chromedriver.exe -Destination C:\SeleniumWebDrivers\ChromeDriver\chromedriver.exe;

# Install Java JDK
RUN powershell -Command `
    Invoke-WebRequest -OutFile javajdk.zip https://github.com/ojdkbuild/ojdkbuild/releases/download/java-11-openjdk-11.0.9.11-2/java-11-openjdk-11.0.9.11-2.windows.ojdkbuild.x86_64.zip; `
    Expand-Archive javajdk.zip -Force -DestinationPath C:\TEMP\javajdk; `
    Move-Item C:\TEMP\javajdk\java-11-openjdk-11.0.9.11-2.windows.ojdkbuild.x86_64 "${Env:ProgramFiles}\Java"; `
    Remove-Item javajdk.zip -Force; `
    setx /M PATH $($Env:PATH + ';' + ${Env:ProgramFiles} + '\Java\bin'); `
    setx /M JAVA_HOME $(${Env:ProgramFiles} + '\Java'); 

# Install Java JRE
RUN powershell -Command `
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; `
    Invoke-WebRequest -OutFile javajre.zip https://github.com/ojdkbuild/ojdkbuild/releases/download/java-11-openjdk-11.0.9.11-2/java-11-openjdk-jre-11.0.9.11-2.windows.ojdkbuild.x86_64.zip; `
    Expand-Archive javajre.zip -Force -DestinationPath C:\TEMP\javajre; `
    Move-Item C:\TEMP\javajre\java-11-openjdk-jre-11.0.9.11-2.windows.ojdkbuild.x86_64 "${Env:ProgramFiles}\Java"; `
    Remove-Item javajre.zip -Force; `
    setx /M PATH $($Env:PATH + ';' + ${Env:ProgramFiles} + '\Java'); `
    setx /M java $(${Env:ProgramFiles} + '\Java'); `
    setx /M java_8 $(${Env:ProgramFiles} + '\Java');

# Cleanup after installs
RUN powershell -Command Remove-Item C:\TEMP -Recurse;
 
# Copy & run Azure Pipelines Agent startup script
COPY start.ps1 .
CMD powershell .\start.ps1


WORKDIR /azp

COPY start.ps1 .

CMD powershell .\start.ps1