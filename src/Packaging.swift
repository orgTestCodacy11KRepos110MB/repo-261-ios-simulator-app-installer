func packageApp(appPath: String, #deviceIdentifier: String, #outputPath: String?, #packageLauncherPath: String?, #fileManager: NSFileManager) {
    let sourcePath = appPath
        |> getFullPath
        >>= validateFileExistence(fileManager: fileManager)
    
    // TODO: Result<T,E> would be better for error handling.
    switch (isRequiredXcodeIsInstalled(), sourcePath) {
    case (false, _):
        println("You need to have \(RequiredXcodeVersion) installed and selected via xcode-select.")
    case (_, .None):
        println("Provided .app not found at \(appPath)")
    case (true, .Some(let sourcePath)):
        let targetPath = outputPath |> getOrElse(defaultTargetPathForApp(sourcePath))
        let launcherPath = packageLauncherPath |> getOrElse("/usr/local/share/app-package-launcher")
        
        let productFolder = "\(launcherPath)/build"
        let productPath = "\(productFolder)/Release/app-package-launcher.app"
        
        system("xcodebuild -project \(launcherPath)/app-package-launcher.xcodeproj \"PACKAGED_APP=\(sourcePath)\" \"TARGET_DEVICE=\(deviceIdentifier)\" > /dev/null")
        
        fileManager.removeItemAtPath(targetPath, error: nil)
        fileManager.moveItemAtPath(productPath, toPath: targetPath, error: nil)
        fileManager.removeItemAtPath(productFolder, error: nil)
        
        println("\(appPath) successfully packaged to \(targetPath)")
    default:
        fatalError("How did we get here?")
    }
}

func getFullPath(path: String) -> String? {
    return URL(path)?.path
}

func validateFileExistence(#fileManager: NSFileManager)(path: String) -> String? {
    return fileManager.fileExistsAtPath(path) ? path : nil
}

func lastPathComponent(#url: NSURL) -> String? {
    return url.lastPathComponent
}

func URL(path: String) -> NSURL? {
    return NSURL.fileURLWithPath(path)
}

func deletePathExtension(path: String) -> String? {
    return path.stringByDeletingPathExtension
}

func defaultTargetPathForApp(appPath: String) -> String {
    let appName = appPath
        |> URL
        >>= lastPathComponent
        >=> deletePathExtension
    
    return "\(appName!) Installer.app" // I don't know how to handle this nicer without introducing bunch of new types, we know the URL cannot fail, though
}
