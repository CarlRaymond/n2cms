# Migrating N2CMS to Visual Studio 2022

The N2CMS project seems to have stopped some time around late 2017, with a single commit in November, 2018.
The latest version available on NuGet is 2.9.6.19, but there are some bug fixes in the repository after
that date. In particular, my motivation is a fix for [#776](https://github.com/n2cms/n2cms/issues/776),
concerning CKEditor configuration within the <n2> section of web.config. This fix has not been
distributed through a published package on NuGet.

The build process for N2 is somewhat opaque, and it was made for the tooling available with Visual Studio 2017.
Since then there are new versions of the .Net Framework, NuGet, and MSBuild. In places it relies on obsolete
MSBuild tasks, and uses an obsolete version of NuGet. There are several batch files that seem relevant to
building and packaging the source, but it's not clear if they're still the current method of building, or
are just vestiges of olden days.

The goal is to produce working packages from the source using the tooling current with Visual Studio 2022,
namely MSBuild, while making minimal changes to the codebase.

Many of these changes are more easily done with VS Code instead of Visual Studio, but for some tasks,
Visual Studio is preferred.



## Solution Files and MSBuild Files

There are multiple solution, targets, and build files in the codebase:

`\N2.Everything.sln`
: Mentioned in Readme.MD as the entrypoint to exploring the source. Referenced in `n2.deploy.targets`, `n2.proj`

`\src\N2.Sources.sln`
: Referenced in `n2.framework.targets`, `n2.sources.targets`, `n2.proj`

`\src\N2.SourcesCI.sln`
: Not referenced by any MSBuild files, and not mentioned in documentation.

`\build\deploy\WebFormTemplates\N2.Templates.sln`
: Referenced in `N2.Templates.sln`

`\build\deploy\WebFormTemplates\N2.Templates-vs2008.sln`
: Obsolete version of above.

`\build\deploy\MvcTemplates\N2.Templates.Mvc.sln`
: Referenced in `N2.Templates.sln`

`\build\deploy\MvcTemplates\N2.Templates.Mvc-vs2008.sln`
: Obsolete version of above.

`\src\N2.AspNet.IdentitySources.sln`
: Aspnet.Identity/Owin account subsystem for N2 CMS, described in `src\Framework\N2.Security.AspNet.Identity\NamespaceDoc.cs`

`\build\n2.proj`
: This is the principal build script to produce the NuGet packages.

`build\n2.



### Remove Obsolete / Unfinished Projects

The files `N2.Everything.sln` and `N2.Sources.sln` reference the project `N2.Raven.csproj`, which does not compile,
and does not seem to be included in any current NuGet package. It prevents the build script from finishing.
`N2.Everything.sln` also references non-existent projects `AppCS.csproj`, `AppVB.vbproj` and `MvcTest.csproj`.

Action: Remove them from `N2.Sources.sln` using Visual Studio or command line:

    cd n2cms
    dotnet sln .\N2.Everything.sln remove .\src\Framework\Raven\N2.Raven.csproj 
    dotnet sln .\N2.Everything.sln remove examples\Mvc\wwwroot\MvcTest.csproj
    dotnet sln .\N2.Everything.sln remove examples\MinimalCSharp\wwwroot\AppCS.csproj
    dotnet sln .\N2.Everything.sln remove examples\MinimalVisualBasic\wwwroot\AppVB.vbproj
    dotnet sln .\src\N2.Sources.sln remove .\src\Framework\Raven\N2.Raven.csproj

### Fix Up Project Paths

Some projects have incorrect paths in the solution files. Action: Patch in Visual Studio or command line:

    dotnet sln .\src\N2.SourcesCI.sln remove .\src\Mvc\MvcTemplates\N2.Management.csproj
    dotnet sln .\src\N2.SourcesCI.sln add .\src\Mvc\MvcTemplates\N2\N2.Management.csproj (see note)
    dotnet sln .\src\N2.AspNet.IdentitySources.sln remove .\src\Mvc\MvcTemplates\N2.Management.csproj
    dotnet sln .\src\N2.AspNet.IdentitySources.sln add .\src\Mvc\MvcTemplates\N2\N2.Management.csproj (see note)

Note: You may get an error message here about importing Microsoft.WebApplication.targets that probably is not an issue.

### Fix Up References in WebApplication Projects

Likely no action needed here. MSBuild defines `VSToolsPath` correctly for VS2022, so Microsoft.WebApplication.targets
is found.

## Update NuGet Usage

### Package Restore Process

The method to integrate NuGet package restore into the build process has changed since version
2.7. See [The right way to restore NuGet packages](http://blog.davidebbo.com/2014/01/the-right-way-to-restore-nuget-packages.html).

Actions:

* Remove the `<Import.../>` referencing `NuGet.targets` from all .csproj files which contain it.
In vscode, search in regex mode for `<Import Project="\$\(SolutionDir\)\\\.nuget\\NuGet\.targets" [^/]+/>\n` and
replace with nothing.
* Remove the `<Error Condition="!Exists('$(SolutionDir)\.nuget\NuGet.targets')" ...` from all .csproj files which contain it.
* Remove the files `NuGet.exe`, `NuGet.targets`, and `NuGet.config` from `\src\.nuget` folder. Leave `packages.config`,
because it is used by the `Test` target in `N2.proj`.
* Add file `NuGet.config` in root folder which specifies a project-wide packages folder
* Edit `N2.Sources.sln` and `N2.SourcesCI.sln` to remove solution items related to NuGet. Search .sln files for
`.nuget\NuGet.Config`. Remove the surrounding lines staring with `Project(...` through the line with `EndProject` (8 lines).
### Replace References to Embedded NuGet.exe

Use the system's installed NuGet to create the packages.
Update `build\n2.deploy.targets` and `build\n2.dinamico.targets`,
replacing `$(BuildFolder)\lib\NuGet.exe` with `NuGet.exe`. 

### Migrate to PackageReference Format

Use Visual Studio to migrate from packages.config format to package references
in the project files. Right-click on a packages.config file and select
**Migrate packages.config to PackageReference...**.

//## Update to .Net Framework 4.8.1
//
//Actions: Use vscode to search-and-replace `<TargetFrameworkVersion>v[0-9\.]+<TargetFrameworkVersion>` (using regex mode)
//with `<TargetFrameworkVersion>v4.8.1</TargetFrameworkVersion>`.

### Patch N2.Templates.Mvc.csproj
Edit `src\Mvc\MvcTemplates\N2.Templates.Mvc.csproj` to add

    <Reference Include="System.Xml.Linq" />


Open solution in Visual Studio to ensure projects load.

## Replace Obsolete Tasks

The build file for packing the source uses a task in MSBuild.Community.Tasks, but that assembly has obsolete dependencies.
Remove the import of MSBuild.Community.Tasks and add the FileUpdate task with some inline code in `n2.proj`

    <UsingTask
    	TaskName="FileUpdate"
    	TaskFactory="RoslynCodeTaskFactory"
    	AssemblyFile="$(MSBuildToolsPath)\Microsoft.Build.Tasks.Core.dll">
    	<ParameterGroup>
			<Files ParameterType="Microsoft.Build.Framework.ITaskItem[]" Required="true" />
			<Regex ParameterType="System.String" Required="true" />
			<ReplacementText ParameterType="System.String" Required="true" />
		</ParameterGroup>
		<Task>
			<Using Namespace="System"/>
			<Using Namespace="System.IO"/>
			<Using Namespace="System.Text.RegularExpressions" />
			<Code Type="Fragment" Language="cs">
				<![CDATA[
				if (Files.Length > 0)
				{
					for (int i=0; i < Files.Length; i++)
					{
						ITaskItem item = Files[i];
						string path = item.GetMetadata("FullPath");
						File.WriteAllText(path, System.Text.RegularExpressions.Regex.Replace(File.ReadAllText(path), Regex, ReplacementText, RegexOptions.IgnoreCase));
					}
				}
				]]>
			</Code>
		</Task>
	</UsingTask>

    
## Compile

### Framework/N2:

Remove `using NHibernate.Mapping` in Collections\CollectionExtensions.cs and Configuration\DatabaseSection

## Unit Testing

On exploring the test projects using NUnit, there are many failing tests. It doesn't seem productive to
clean that up.