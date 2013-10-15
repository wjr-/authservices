$ErrorActionPreference = "Stop"

$status = (git status)
$clean = $status| select-string "working directory clean"

if ("$clean" -eq "")
{
  echo "Working copy is not clean. Cannot proceed."
  exit
}

$master = $status | select-string "On branch master"

if ("$master" -eq "")
{
  echo "Releases are only allowed from the master branch."
  exit
}

pushd ..\Kentor.AuthServices
del bin\Release\*.dll

function Increment-PatchNumber
{
	$versionPattern = "[0-9]+(\.([0-9]+|\*)){1,3}"
	$assemblyVersionPattern = '^\[assembly: AssemblyVersion\("([0-9]+(\.([0-9]+|\*)){1,3})"\)'  
	$rawVersionNumberGroup = get-content Properties\AssemblyInfo.cs| select-string -pattern $assemblyVersionPattern | % { $_.Matches }

	$rawVersionNumber = $rawVersionNumberGroup.Groups[1].Value  
	$versionParts = $rawVersionNumber.Split('.')  
	$versionParts[2] = ([int]$versionParts[2]) + 1  
	$updatedAssemblyVersion = "{0}.{1}.{2}" -f $versionParts[0], $versionParts[1], $versionParts[2]

	(get-content Properties\AssemblyInfo.cs) | % { 
		% { $_ -replace $versionPattern, $updatedAssemblyVersion }
	} | set-content Properties\AssemblyInfo.cs

	return $updatedAssemblyVersion
}

$version = Increment-PatchNumber

echo "Version updated to $version, commiting and tagging..."

git commit -a -m "Updated version number to $version for release."
git tag v$version

echo "Building package..."

nuget pack -build -outputdirectory ..\nuget

$version = Increment-PatchNumber

echo "Version updated to $version for development, committing..."

git commit -a -m "Updated version number to $version for development."

popd