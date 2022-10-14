# Really clean up.
msbuild .\build\n2.proj -t:clean

# Remove all obj and bin folders
Get-ChildItem -include bin,obj -Recurse -Force | Remove-Item -force -Recurse

# Remove all packages folders
Get-ChildItem -include packages -Recurse -Force | Remove-Item -force -Recurse

# Remove output folder
if (Test-Path .\output) {
    Remove-Item .\output -Recurse -Force
}
