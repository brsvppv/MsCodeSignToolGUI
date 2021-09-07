[Net.ServicePointManager]::SecurityProtocol = 'Tls12'
[void][System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
[void][System.Reflection.Assembly]::LoadWithPartialName('presentationframework')
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName PresentationCore, PresentationFramework
[xml]$XAML = @"
<Window
xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
     
        Title="CodeSignGUI" Height="200" Width="355" ResizeMode="NoResize" WindowStartupLocation="CenterScreen">
        <Grid Background="{DynamicResource {x:Static SystemColors.WindowBrushKey}}" Height="200" Width="355" VerticalAlignment="Center" HorizontalAlignment="Center" >
            <TextBox Name="txtSignToolPath" Text="Select Code SignTool Path" HorizontalAlignment="Left" Height="20" Width="300" Margin="15,31,0,0" VerticalAlignment="Top"  FontSize="11" IsReadOnly="true"/>
            <TextBox Name="txtCertificatePath" Text="Select Code Signing Certificate" HorizontalAlignment="Left" Height="20" Width="300" Margin="15,56,0,0" VerticalAlignment="Top"  FontSize="11" IsReadOnly="false"/>
            <TextBox Name="txtFileToSignPath" Text="Select File to Sign" HorizontalAlignment="Left" Height="20" Width="300" Margin="15,83,0,0" VerticalAlignment="Top" FontSize="11" IsReadOnly="false"/>   
            <Button Name="btnSelecSignToolPath" Content="..." Margin="314,31,0,0" VerticalAlignment="Top" Height="20"  Width="27" HorizontalAlignment="Left"/>
            <Button Name="btnSelectCert" Content="..." HorizontalAlignment="Left" Margin="314,56,0,0" VerticalAlignment="Top" Width="27" Height="20"/>
            <Button Name="btnFile" Content="..." HorizontalAlignment="Left" Margin="314,83,0,0" VerticalAlignment="Top" Width="27" Height="20"/>
            <Button Name="btnPerformCodeSign" Content="Perform Code Signing" Margin="0,150,0,0" VerticalAlignment="Top" Height="23" Width="335" HorizontalAlignment="Center" />
            <Label Name="lblCertPswd" Content="Certificate Password:" HorizontalAlignment="Left" Margin="5,104,0,0" VerticalAlignment="Top" Width="117" Height="27"/>
            <PasswordBox Name="pswdbCert" HorizontalAlignment="Left" Margin="127,108,0,0" VerticalAlignment="Top" Width="214"  Height="20"/>      
            </Grid>
    </Window>
"@

#Read XAML
$reader = (New-Object System.Xml.XmlNodeReader $xaml) 
try { $Form = [Windows.Markup.XamlReader]::Load( $reader ) }
catch { Write-Host "Unable to load Windows.Markup.XamlReader"; exit }
# Store Form Objects In PowerShell
$xaml.SelectNodes("//*[@Name]") | ForEach-Object { Set-Variable -Name ($_.Name) -Value $Form.FindName($_.Name) }

$fdAlg = "SHA256"
$tURL = "http://timestamp.digicert.com"
Function SelectCertificate { 
    $FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{
        Multiselect = $false # Multiple files can be chosen
        Filter      = 'Certificate (*.pfx)|*.pfx' # Specified file types
    }
    [void]$FileBrowser.ShowDialog()
    
    If ($FileBrowser.FileNames -like "*\*")
    { $fullPath = $FileBrowser.FileNames }
    else {
        
        $res = [System.Windows.Forms.MessageBox]::Show("No File Selected, Try Again ?", "Select a location", [System.Windows.Forms.MessageBoxButtons]::YesNo)
        if ($res -eq "No") {
            return
        }
    }
    $filedirectory = Split-Path -Parent $FileBrowser.FileName
    $certName = [System.IO.Path]::GetFileName($fullPath)          
    $txtCertificatePath.Text = "$filedirectory" + "\" + "$certName"
    return $FileBrowser.FileNames   
}
Function SelectFileToSign { 
    $FileBrowser = New-Object System.Windows.Forms.OpenFileDialog -Property @{
        Multiselect = $false # Multiple files can be chosen
        #Filter      = 'Certificate (*.pfx)|*.pfx' # Specified file types
    }
    [void]$FileBrowser.ShowDialog()
    
    If ($FileBrowser.FileNames -like "*\*")
    { $fullPath = $FileBrowser.FileNames }
    else {
        
        $res = [System.Windows.Forms.MessageBox]::Show("No File Selected, Try Again ?", "Select a location", [System.Windows.Forms.MessageBoxButtons]::YesNo)
        if ($res -eq "No") {
            return
        }
    }
    $filedirectory = Split-Path -Parent $FileBrowser.FileName
    $fname = [System.IO.Path]::GetFileName($fullPath)          
    $txtFileToSignPath.Text = "$filedirectory" + "\" + "$fname"
    return $FileBrowser.FileNames   
}
function SelectDirectory {
 
    $browse = New-Object System.Windows.Forms.FolderBrowserDialog
    $browse.SelectedPath = "C:\"
    $browse.ShowNewFolderButton = $true
    $browse.Description = "Select a directory"

    $loop = $true
    while ($loop) {
        if ($browse.ShowDialog() -eq "OK") {
            $loop = $false
		
            $browse.SelectedPath
            $txtSignToolPath.Text = $browse.SelectedPath
            $browse.Dispose()
		
        }
        else {
            $res = [System.Windows.Forms.MessageBox]::Show("No Directroy Selected. Try Again?", "Select a location", [System.Windows.Forms.MessageBoxButtons]::YesNo)
            if ($res -eq "No") {
                #####
                return
            }
        }
    }
}
function ButtonEnable{
    if ($txtCertificatePath.Text -eq "Select Code Signing Certificate" -bor $txtFileToSignPath.Text -eq "Select File to Sign" -bor $pswdbCert.Password -eq ""){
        $btnPerformCodeSign.IsEnabled = $false
    }
    else{
        $btnPerformCodeSign.IsEnabled = $true
    }
}
$Form.Add_Loaded( {
        $btnPerformCodeSign.IsEnabled = $false
        $txtSignToolPath.Text = "C:\Program Files (x86)\Windows Kits\10\bin\10.0.19041.0\x64"
        #$pswdbCert.PasswordChar = '*'
    })
$txtCertificatePath.Add_TextChanged({
    ButtonEnable
})
$txtFileToSignPath.Add_TextChanged({
    ButtonEnable
})
$pswdbCert.Add_PasswordChanged({
    ButtonEnable
})

#default sign tool location:
#"C:\Program Files (x86)\Windows Kits\10\bin\10.0.19041.0\x64"
$btnSelecSignToolPath.Add_Click( {
        SelectDirectory
    })

$btnSelectCert.Add_Click( {
        SelectCertificate
        
    })
$btnFile.Add_Click( {
        SelectFileToSign
    })

#Set-Location "$signToolLocaion"
$btnPerformCodeSign.Add_Click( {
    Set-Location $txtSignToolPath.Text
    try{
        ./signtool.exe sign /t "$tURL" /fd $fdAlg /f $txtCertificatePath.Text /p $pswdbCert.Password $txtFileToSignPath.Text
    }
    Catch{
        [System.Windows.MessageBox]::Show("An Error Occured During Signing  $_", 'ERROR', 'OK', 'Error') 
    }
    [System.Windows.MessageBox]::Show("Completed", 'File Sign Result', 'OK', 'Information')
})

$Form.ShowDialog() | out-null   