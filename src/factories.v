module main

import gx
import gg
import math
import time
import ghostnear.vstorm

// Background factory
fn create_background() &vstorm.Node {
	mut node := &vstorm.Node{}
	node.add_component(&gx.Color{
		r: 0x11
		g: 0x11
		b: 0x11
	}, 'color')

	node.add_function(fn (mut node vstorm.Node) {
		mut window := node.context.win
		mut ggc := window.gg
		w_size := window.get_size()
		ggc.draw_rect_filled(0, 0, w_size.x, w_size.y, &gx.Color(node.get_component('color')))
	}, 'draw')

	return node
}

enum GameElement {
	pos_null = 0
	pos_x
	pos_o
}

enum GameEnd {
	no = 0
	equal
	not_equal
}

struct GameEndLine {
	start vstorm.NodeV2D
	end   vstorm.NodeV2D
}

struct GameState {
mut:
	grid [3][3]GameElement
	turn GameElement = .pos_x
	state GameEnd
	line GameEndLine
}

// Grid factory
fn create_grid() &vstorm.Node {
	mut node := &vstorm.Node{}
	node.add_component(&time.StopWatch{}, 'reset_timer')

	node.add_component(&gx.Color{
		r: 0xAA
		g: 0xAA
		b: 0xAA
	}, 'color')

	node.add_component(&gx.Color{
		r: 0xFF
		g: 0x55
		b: 0x55
	}, 'win_color')

	node.add_component(&GameState{}, 'state')

	node.add_component(&gx.Color{
		r: 0x22
		g: 0x22
		b: 0x22
	}, 'highlight_color')

	node.add_component(&vstorm.NodeV2D{
		x: -1
		y: -1
	}, 'highlighted_cell')

	node.add_component(&vstorm.NodeV2D{
		x: 25
		y: 25
		r: false
	}, 'padding')

	node.add_function(fn (mut node vstorm.Node) {
		mut window := node.context.win
		mut ggc := window.gg
		w_size := window.get_size()
		min_size := math.min(w_size.x, w_size.y)
		scale := window.get_scale_relative_to(vstorm.NodeV2D{
			x: 960
			y: 540
		})
		padding := &vstorm.NodeV2D(node.get_component('padding'))
		
		// Grid area
		result_rect := vstorm.NodeR2D{
			pos: vstorm.NodeV2D{
				x: (w_size.x - min_size) / 2 + padding.x
				y: (w_size.y - min_size) / 2 + padding.y
			}
			siz: vstorm.NodeV2D{
				x: min_size - 2 * padding.x
				y: min_size - 2 * padding.y
			}
		}
		cell_size := vstorm.NodeV2D{
			x: result_rect.siz.x / 3
			y: result_rect.siz.y / 3
		}

		// Draw highlighted cell
		high_cell := &vstorm.NodeV2D(node.get_component('highlighted_cell'))
		if high_cell.x != -1 && high_cell.y != -1 {
			ggc.draw_rect_filled(
				result_rect.pos.x + cell_size.x * high_cell.x,
				result_rect.pos.y + cell_size.y * high_cell.y,
				cell_size.x, cell_size.y,
				&gx.Color(node.get_component('highlight_color'))
			)
		}

		// Draw the lines
		config := gg.PenConfig{
			color: &gx.Color(node.get_component('color'))
			thickness: int(7 * scale)
		}
		for i := 1; i <= 2; i++ {
			ggc.draw_line_with_config(
				result_rect.pos.x + i * cell_size.x,
				result_rect.pos.y,
				result_rect.pos.x + i * cell_size.x,
				result_rect.pos.y + result_rect.siz.y,
				config
			)
			ggc.draw_line_with_config(
				result_rect.pos.x,
				result_rect.pos.y + i * cell_size.y,
				result_rect.pos.x + result_rect.siz.x,
				result_rect.pos.y + i * cell_size.y,
				config
			)
		}

		// Draw the winning line if it exists
		mut game_state := &GameState(node.get_component('state'))
		win_thickness := int(4 * scale)
		win_config := gg.PenConfig{
			color: &gx.Color(node.get_component('win_color'))
			thickness: win_thickness
		}
		if game_state.state == .not_equal {
			ggc.draw_line_with_config(
				result_rect.pos.x + (game_state.line.start.x + 0.5) * cell_size.x,
				result_rect.pos.y + (game_state.line.start.y + 0.5) * cell_size.y,
				result_rect.pos.x + (game_state.line.end.x + 0.5) * cell_size.x,
				result_rect.pos.y + (game_state.line.end.y + 0.5) * cell_size.y,
				win_config
			)
		}

		// Draw the text
		textcfg := gx.TextCfg{
			color: 			&gx.Color(node.get_component('color'))
			align:         	gx.HorizontalAlign.center
			vertical_align: gx.VerticalAlign.middle
			size: 			int(scale * 112)
			bold:			true
		}
		for i := 0; i < 3; i++ {
			for j := 0; j < 3; j++ {
				if game_state.grid[i][j] != .pos_null {
					mut str := 'X'
					if game_state.grid[i][j] == .pos_o {
						str = 'O'
					}
					ggc.draw_text(
						int(result_rect.pos.x + cell_size.x * (f32(i) + 0.5)),
						int(result_rect.pos.y + cell_size.y * (f32(j) + 0.5)),
						str, textcfg
					)
				}
			}
		}
	}, 'draw')

	node.add_function(fn (mut node vstorm.Node) {
		mut game_state := &GameState(node.get_component('state'))
		if game_state.state != .no {
			mut timer := &time.StopWatch(node.get_component('reset_timer'))
			if timer.elapsed().seconds() >= 2.5 {
				// Reset table
				game_state.grid = [3][3]GameElement{}
				game_state.turn = .pos_x
				game_state.line = GameEndLine{}
				game_state.state = .no

				// Reset timer
				timer.restart()
				timer.pause()
			}
		}
	}, 'update')

	node.add_function(fn (mut node vstorm.Node) {
		mut window := node.context.win
		w_size := window.get_size()
		min_size := math.min(w_size.x, w_size.y)
		mouse_pos := window.get_mouse_pos()
		padding := &vstorm.NodeV2D(node.get_component('padding'))
		e := window.latest_event
		
		// Grid area
		result_rect := vstorm.NodeR2D{
			pos: vstorm.NodeV2D{
				x: (w_size.x - min_size) / 2 + padding.x
				y: (w_size.y - min_size) / 2 + padding.y
			}
			siz: vstorm.NodeV2D{
				x: min_size - 2 * padding.x
				y: min_size - 2 * padding.y
			}
		}
		cell_size := vstorm.NodeV2D{
			x: result_rect.siz.x / 3
			y: result_rect.siz.y / 3
		}

		match e.typ {
			.mouse_leave,
			.mouse_enter,
			.mouse_move {
				// Check where the mouse is and mark the square
				// Only if game didn't end already
				mut high_cell := &vstorm.NodeV2D(node.get_component('highlighted_cell'))
				mut game_state := &GameState(node.get_component('state'))
				high_cell.x = -1
				high_cell.y = -1
				if game_state.state == .no {
					for i := 0; i < 3; i++ {
						for j := 0; j < 3; j++ {
							p_rect := vstorm.NodeR2D{
								pos: vstorm.NodeV2D{
									x: result_rect.pos.x + cell_size.x * i
									y: result_rect.pos.y + cell_size.y * j
								}
								siz: cell_size
							}
							if p_rect.check_inside(mouse_pos) &&
								game_state.grid[i][j] == .pos_null {
								high_cell.x = i
								high_cell.y = j
							}
						}
					}
				}
			}
			.mouse_up {
				// Get highlighted cell and add an X or O
				mut high_cell := &vstorm.NodeV2D(node.get_component('highlighted_cell'))
				if high_cell.x != -1 && high_cell.y != -1 {
					mut game_state := &GameState(node.get_component('state'))
					game_state.grid[int(high_cell.x)][int(high_cell.y)] = game_state.turn
					if game_state.turn == .pos_x {
						game_state.turn = .pos_o
					}
					else {
						game_state.turn = .pos_x
					}

					// Check for win
					for j := 0; j < 3 && game_state.state == .no; j++ {
						// Per line
						if game_state.grid[0][j] != .pos_null {
							game_state.state = .not_equal
							game_state.line = GameEndLine {
								start: vstorm.NodeV2D{
									x: 0
									y: j
								}
								end: vstorm.NodeV2D{
									x: 2
									y: j
								}
							}
							for i := 1; i < 3; i++ {
								if game_state.grid[i][j] != game_state.grid[0][j] {
									game_state.state = .no
								}
							}
						}

						// Per column
						if game_state.grid[j][0] != .pos_null && game_state.state == .no {
							game_state.state = .not_equal
							game_state.line = GameEndLine {
								start: vstorm.NodeV2D{
									x: j
									y: 0
								}
								end: vstorm.NodeV2D{
									x: j
									y: 2
								}
							}
							for i := 1; i < 3; i++ {
								if game_state.grid[j][i] != game_state.grid[j][0] {
									game_state.state = .no
								}
							}
						}
					}

					// Diagonal 1
					if game_state.grid[0][0] != .pos_null && game_state.state == .no {
						game_state.state = .not_equal
						game_state.line = GameEndLine {
							start: vstorm.NodeV2D{
								x: 0
								y: 0
							}
							end: vstorm.NodeV2D{
								x: 2
								y: 2
							}
						}
						for i := 1; i < 3; i++ {
							if game_state.grid[i][i] != game_state.grid[0][0] {
								game_state.state = .no
							}
						}
					}

					// Diagonal 2
					if game_state.grid[2][0] != .pos_null && game_state.state == .no {
						game_state.state = .not_equal
						game_state.line = GameEndLine {
							start: vstorm.NodeV2D{
								x: 2
								y: 0
							}
							end: vstorm.NodeV2D{
								x: 0
								y: 2
							}
						}
						for i := 1; i < 3; i++ {
							if game_state.grid[2 - i][i] != game_state.grid[2][0] {
								game_state.state = .no
							}
						}
					}

					// Last, check for equal
					if game_state.state == .no {
						game_state.state = .equal
						for i := 0; i < 3; i++ {
							for j := 0; j < 3; j++ {
								if game_state.grid[i][j] == .pos_null {
									game_state.state = .no
								}
							}
						}
					}

					// If round end, start the timer
					if game_state.state != .no {
						mut timer := &time.StopWatch(node.get_component('reset_timer'))
						timer.restart()
					}
				}
			}
			else {}
		}
	}, 'event')
	return node
}