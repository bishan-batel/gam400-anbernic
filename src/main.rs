use std::error::Error;

use human_bytes::human_bytes;
use memory_stats::memory_stats;
use winit::{
    application::ApplicationHandler,
    event_loop::EventLoop,
    window::{Window, WindowAttributes},
};

#[derive(Default)]
struct App {
    window: Option<Window>,
}

impl ApplicationHandler for App {
    fn resumed(&mut self, event_loop: &winit::event_loop::ActiveEventLoop) {
        self.window = Some(
            event_loop
                .create_window(WindowAttributes::default())
                .unwrap(),
        );
    }

    fn window_event(
        &mut self,
        event_loop: &winit::event_loop::ActiveEventLoop,
        _window_id: winit::window::WindowId,
        event: winit::event::WindowEvent,
    ) {
        use winit::event::WindowEvent as Ev;

        match event {
            Ev::CloseRequested => {
                println!("Closing");
                event_loop.exit();
            }

            Ev::RedrawRequested => {
                let window = self.window.as_ref().unwrap();
                window.request_redraw();

                if let Some(usage) = memory_stats() {
                    println!(
                        "Physical Memory: {}",
                        human_bytes(usage.physical_mem as f64)
                    );
                }
            }

            _ => {}
        }
    }
}

fn main() -> Result<(), Box<dyn Error>> {
    println!("Hello, world!");

    let event_loop = EventLoop::new()?;

    let mut app = App::default();

    event_loop.run_app(&mut app)?;

    Ok(())
}
