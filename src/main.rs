use clap::{Parser, Subcommand};
use cxx_qt_build::{CxxQtBuilder, QmlModule};
use std::io::Write;
use std::path::{Path, PathBuf};

fn main() {
    let mut args = Args::parse();
    std::fs::create_dir_all(&args.out_dir).unwrap();

    let mut extra_include_dirs = Vec::new();

    if let Some(header_path) = &args.extra_header_file {
        std::fs::create_dir_all(header_path.parent().unwrap()).unwrap();
        let mut file = std::fs::OpenOptions::new()
            .create(true)
            .truncate(true)
            .write(true)
            .open(header_path)
            .unwrap();
        for line in &args.extra_header_line {
            writeln!(&mut file, "{line}").unwrap();
        }
        file.sync_all().unwrap();
        extra_include_dirs.push(header_path.parent().unwrap());
    }

    unsafe {
        setup_env(&args);
    };

    args.cpp_file
        .iter_mut()
        .for_each(|path| *path = pathx::relative_to(&args.crate_directory, path));
    args.file
        .iter_mut()
        .for_each(|path| *path = pathx::relative_to(&args.crate_directory, path));

    let mut builder = if let Some(new_module) = args.new_qml_module {
        let mut module = QmlModule::new(new_module.as_str());
        module = module.qml_files(args.qml_file);
        CxxQtBuilder::new_qml_module(module)
    } else {
        CxxQtBuilder::new()
    };

    let include_prefix = args.include_prefix.unwrap_or(args.crate_name.clone());

    for qrc in args.qrc {
        builder = builder.qrc(qrc);
    }

    for initializer in args.initializer {
        let (signature, path) = initializer.split_once(";").unwrap();

        let path = pathx::relative_to(&args.crate_directory, Path::new(path));

        builder = builder.initializer(qt_build_utils::Initializer {
            file: Some(path),
            ..qt_build_utils::Initializer::default_signature(signature)
        });
    }

    builder = builder.include_prefix(&include_prefix).files(args.file);

    match args.command {
        Command::Build => {
            builder.build();
        }
        Command::Generate => {
            builder.generate();
        }
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
    }
}

unsafe fn setup_env(args: &Args) {
    let out_dir = &args.out_dir.canonicalize().unwrap();

    unsafe {
        std::env::set_var("OUT_DIR", out_dir);
        std::env::set_var("QMAKE", args.qmake.canonicalize().unwrap());
        std::env::set_var("QT_VERSION_MAJOR", "6");

        std::fs::create_dir_all(&args.out_dir).unwrap();
        std::env::set_var("TARGET", current_platform::CURRENT_PLATFORM);
        std::env::set_var("HOST", current_platform::CURRENT_PLATFORM);
        std::env::set_var("OPT_LEVEL", "3");

        let absolute = args.crate_directory.canonicalize().unwrap();
        std::env::set_var("CARGO_MANIFEST_DIR", &absolute);
        std::env::set_current_dir(absolute).unwrap();
        println!(
            "current_dir: {}",
            std::env::current_dir().unwrap().display()
        );
        std::env::set_var("CARGO_PKG_NAME", &args.crate_name);
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
    new_qml_module: Option<String>,

    #[arg(long)]
    qml_file: Vec<PathBuf>,

    #[command(subcommand)]
    command: Command,
}

#[derive(Debug, Subcommand)]
enum Command {
    Build,
    Generate,
}
