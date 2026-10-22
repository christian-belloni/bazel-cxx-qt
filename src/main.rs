use clap::{Parser, Subcommand};
use cxx_qt_build::{CxxQtBuilder, QmlModule};
use std::io::Write;
use std::path::{Path, PathBuf};

fn main() {
    let mut args = Args::parse();
    std::fs::create_dir_all(&args.out_dir).unwrap();

    unsafe {
        setup_env(&args);
    };

    args.cpp_file
        .iter_mut()
        .for_each(|path| *path = pathx::relative_to(&args.crate_directory, path));
    args.file
        .iter_mut()
        .for_each(|path| *path = pathx::relative_to(&args.crate_directory, path));

    println!("{args:?}");

    let mut builder = if let Some(new_module) = args.new_qml_module {
        let mut module = QmlModule::new(new_module.as_str());
        module = module.qml_files(args.qml_file);
        CxxQtBuilder::new_qml_module(module)
    } else {
        CxxQtBuilder::new()
    };

    builder = builder.crate_include_root(args.crate_include_root);

    for dir in args.out_include_dir {
        let dir = args.out_dir.join(dir);
        println!("out_include_dir: {}", dir.display());
        builder = builder.include_dir(&dir);
    }

    let include_prefix = args.include_prefix.unwrap_or(args.crate_name.clone());

    for qrc in args.qrc {
        builder = builder.qrc(qrc);
    }

    for module in args.qt_module {
        builder = builder.qt_module(&module);
    }

    if let Some(header_path) = &args.extra_header_file {
        std::fs::create_dir_all(header_path.parent().unwrap()).unwrap();
        let mut file = std::fs::OpenOptions::new()
            .create(true)
            .truncate(true)
            .write(true)
            .open(header_path)
            .unwrap();
        writeln!(&mut file, "#pragma once").unwrap();
        for line in &args.extra_header_line {
            writeln!(&mut file, "{line}").unwrap();
        }
        file.sync_all().unwrap();
        builder = builder.include_dir(header_path.parent().unwrap());
    }

    for initializer in args.initializer {
        let (signature, path) = initializer.split_once(";").unwrap();

        let path = pathx::relative_to(&args.crate_directory, Path::new(path));

        builder = builder.initializer(qt_build_utils::Initializer {
            file: Some(path),
            ..qt_build_utils::Initializer::default_signature(signature)
        });
    }

    let mut built = builder
        .cpp_files(args.cpp_file)
        .include_prefix(&include_prefix)
        .files(args.file)
        .build();

    if let Some(command) = args.command {
        match command {
            Command::Export => built.export(),
            Command::ReExport { lib } => {
                for lib in lib {
                    built = built.reexport_dependency(&lib)
                }
                built.export();
            }
        }
    }
}

unsafe fn setup_env(args: &Args) {
    let out_dir = &args.out_dir.canonicalize().unwrap();

    println!("{}", out_dir.display());

    let mut current = std::env::var("CXXFLAGS").unwrap_or_default();

    for dependency in &args.cxxqt_dependency {
        current.push_str(&format!(
            " -I {}",
            dependency.canonicalize().unwrap().display()
        ));
    }

    unsafe {
        if let Ok(cxx) = std::env::var("CXX") {
            let cxx = PathBuf::from(cxx).canonicalize().unwrap();
            std::env::set_var("CXX", cxx);
        }

        std::env::set_var("CXXFLAGS", current);
        std::env::set_var("OUT_DIR", out_dir);
        std::env::set_var("QMAKE", args.qmake.canonicalize().unwrap());
        std::env::set_var("QT_VERSION_MAJOR", "6");

        std::fs::create_dir_all(&args.out_dir).unwrap();
        std::env::set_var("TARGET", &args.target_triple);
        std::env::set_var("HOST", &args.host_triple);
        std::env::set_var("OPT_LEVEL", args.opt_level.to_string());

        let absolute = args.crate_directory.canonicalize().unwrap();
        std::env::set_var("CARGO_MANIFEST_DIR", &absolute);
        std::env::set_current_dir(absolute).unwrap();
        println!(
            "current_dir: {}",
            std::env::current_dir().unwrap().display()
        );
        std::env::set_var("CARGO_PKG_NAME", &args.crate_name);

        if let Some(links) = &args.cargo_manifest_links {
            std::env::set_var("CARGO_MANIFEST_LINKS", links);
        } else {
            std::env::set_var("CARGO_MANIFEST_LINKS", &args.crate_name);
        }
    };
}

#[derive(Debug, Parser)]
struct Args {
    #[arg(long)]
    initializer: Vec<String>,

    #[arg(long)]
    file: Vec<PathBuf>,

    #[arg(long)]
    crate_include_root: Option<String>,

    #[arg(long)]
    out_include_dir: Vec<PathBuf>,

    #[arg(long)]
    include_prefix: Option<String>,

    #[arg(long)]
    qrc: Vec<PathBuf>,

    #[arg(long)]
    qt_module: Vec<String>,

    #[arg(long)]
    cpp_file: Vec<PathBuf>,

    #[arg(long)]
    out_dir: PathBuf,

    #[arg(long)]
    qmake: PathBuf,

    #[arg(long)]
    host_triple: String,

    #[arg(long)]
    target_triple: String,

    #[arg(long)]
    opt_level: u8,

    #[arg(long)]
    crate_directory: PathBuf,

    #[arg(long)]
    crate_name: String,

    #[arg(long)]
    cargo_manifest_links: Option<String>,

    #[arg(long)]
    extra_header_file: Option<PathBuf>,

    #[arg(long)]
    extra_header_line: Vec<String>,

    #[arg(long)]
    cxxqt_dependency: Vec<PathBuf>,

    #[arg(long)]
    new_qml_module: Option<String>,

    #[arg(long)]
    qml_file: Vec<PathBuf>,

    #[command(subcommand)]
    command: Option<Command>,
}

#[derive(Debug, Subcommand)]
enum Command {
    Export,
    ReExport {
        #[arg(long)]
        lib: Vec<String>,
    },
}
