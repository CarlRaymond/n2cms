# Migrating N2CMS to Visual Studio 2022

The N2CMS project seems to have stopped some time around late 2017, with a single commit in November, 2018.
The latest version available on NuGet is 2.9.6.19, but there are some bug fixes in the repository after
that date. In particular, my motivation is a fix for [#776](https://github.com/n2cms/n2cms/issues/776),
concerning CKEditor configuration within the <n2> section of web.config. This fix has not been
distributed through NuGet

The build process for N2 is somewhat opaque, and it was made for the tooling available with Visual Studio 2017.
Since then there are new versions of the .Net Framework, NuGet, and MSBuild. In places it relies on obsolete
MSBuild tasks, and uses an obsolete version of NuGet.

This is an attepmt to produce working packages from the source using the tooling current with Visual Studio 2022,
while making minimal changes to the codebase.

Many of these changes are more easily done with VS Code instead of Visual Studio.

## Fix Project References in Solution Files

### Remove Obsolete / Unfinished Projects

The files `N2.Everything.sln` and `N2.Sources.sln` reference the project `N2.Raven`, which does not compile,
and does not seem to be included in any current NuGet package. It prevents the build script from finishing.

Action: Remove it from `N2.Sources.sln` using Visual Studio or command line:

    cd n2cms
    dotnet sln .\N2.Everything.sln remove .\src\Framework\Raven\N2.Raven.csproj 
    dotnet sln .\src\N2.Sources.sln remove .\src\Framework\Raven\N2.Raven.csproj

### Fix Up References in WebApplication Projects



### Fix Up Project Paths

Some projects have incorrect paths in the solution files. Action: Patch in Visual Studio or command line:

    dotnet sln .\N2.Everything.sln remove .\src\Mvc\MvcTemplates\N2.Management.csproj
    dotnet sln .\N2.Everything.sln add .\src\Mvc\MvcTemplates\N2\N2.Management.csproj

## Change the NuGet Package Restore Process

The method to integrate NuGet package restore into the build process has changed since version
2.7. See [The right way to restore NuGet packages](http://blog.davidebbo.com/2014/01/the-right-way-to-restore-nuget-packages.html).

Actions:
    * Remove the `<Import.../>` referencing `NuGet.targets` from all .csproj files which contain it
    * Remove the files `NuGet.exe`, `NuGet.targets`, and `NuGet.config` from `\src\.nuget` folder. Leave `packages.config`,
    because it is used by the `Test` target in `N2.proj`.
    * Modify 


