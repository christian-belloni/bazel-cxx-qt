use cxx_qt_build::{CxxQtBuilder, QmlModule};

fn main() {
    CxxQtBuilder::new_qml_module(
        QmlModule::new("ui")
            .qml_file("qml/main.qml")
            .qml_file("qml/nested/Other.qml"),
    )
    .build();
}
