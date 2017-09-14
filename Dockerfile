FROM microsoft/aspnet:4.6.2
SHELL ["PowerShell"]
ARG source
WORKDIR /app
RUN 	Import-Module WebAdministration;\
	Remove-WebSite -Name 'Default Web Site';\
	Install-WindowsFeature Web-Windows-Auth;\
	Install-WindowsFeature Web-Http-Redirect;\
	md C:\app;New-Website -Name 'mywebapp' -Port 80 -PhysicalPath 'c:\app' ;\
	Set-WebConfigurationProperty -Filter "/system.webServer/security/authentication/windowsAuthentication"  -Name enabled -Value $true ;\
	Set-WebConfigurationProperty -Filter "/system.webServer/security/authentication/anonymousAuthentication"  -Name enabled -Value $false ;\
	Get-WebConfigurationProperty -Filter "/system.webServer/security/authentication/*"  -Name enabled |select Name , value ,ItemXPath |FT -autosize;
 	
COPY ${source:-obj/Docker/publish} /App


RUN DIR;$cert = Import-PfxCertificate -FilePath wepapplication1.pfx -CertStoreLocation Cert:\LocalMachine\My -Password (ConvertTo-SecureString "P@ssW0rD!" -AsPlainText -Force);\
 	New-WebBinding -Name mywebapp -HostHeader $cert.DnsNameList[0].ToString() -Port 443 -Protocol https;\
 	cd IIS:\SslBindings;\
 	Get-childitem -Path Cert:\LocalMachine\My |where Thumbprint  -EQ $cert.Thumbprint |New-Item 0.0.0.0!443;\
    Start-Process 'C:\app\rewrite_amd64_en-US.msi' '/qn' -PassThru | Wait-Process ;\
	IISRESET ;
	

EXPOSE 80 443