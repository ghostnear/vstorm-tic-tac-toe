module main

import ghostnear.vstorm

fn app_init(mut app vstorm.AppContext) {
	mut root := app.root
	mut background := create_background()
	mut grid := create_grid()
	root.add_child(mut background, 'background')
	background.add_child(mut grid, 'grid')
}

fn main() {
	// App data goes here
	mut app_config := vstorm.AppConfig{
		// Window specific configuration
		winconfig: vstorm.WindowConfig{
			title: 'Tic Tac Toe'
			size: vstorm.NodeV2D{
				x: 960
				y: 540
			}
			ui_mode: true
			init_fn: app_init
		}
	}

	// App runner
	mut app := vstorm.new_storm_context(mut app_config)
	app.run()
}
