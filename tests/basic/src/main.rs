use qtbridge::{QApp, qobject};

#[derive(Default)]
pub struct Backend {}

#[qobject(Singleton)]
impl Backend {
    #[qslot]
    fn say_hello(&self) {
        println!("Hello World!")
    }
}

fn main() {
    QApp::new()
        .register::<Backend>()
        .load_qml_from_file("qrc:/qt/qml/ui/qml/main.qml")
        .run();
}
