fn main() {
    slint_build::compile("ui/appwindow.slint").unwrap();

    #[cfg(windows)]
    {
        let mut res = winresource::WindowsResource::new();
        res.set_icon("assets/icon.ico");
        res.set("FileDescription", "Switch Provider");
        res.set("ProductName", "Switch Provider");
        res.set("OriginalFilename", "switch-provider.exe");
        res.compile().unwrap();
    }
}
