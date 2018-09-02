-- GENERATED CODE
-- Node Box Editor, version 0.9.0
-- Namespace: test

minetest.register_node("test:node_1", {
	tiles = {
		"default_wood.png",
		"default_wood.png",
		"default_wood.png",
		"default_wood.png",
		"default_wood.png",
		"default_wood.png"
	},
	drawtype = "nodebox",
	paramtype = "light",
	node_box = {
		type = "fixed",
		fixed = {
			{-0.5, -0.5, -0.5, -0.4375, -0.4375, -0.375}, -- NodeBox1
			{-0.4375, -0.5, -0.5, -0.375, -0.4375, -0.25}, -- NodeBox2
			{-0.375, -0.5, -0.5, -0.3125, -0.4375, -0.125}, -- NodeBox3
			{-0.3125, -0.5, -0.5, -0.25, -0.4375, 0}, -- NodeBox4
			{-0.25, -0.5, -0.5, -0.1875, -0.4375, 0.125}, -- NodeBox5
			{-0.1875, -0.5, -0.5, -0.125, -0.4375, 0.25}, -- NodeBox6
			{-0.125, -0.5, -0.5, -0.0625, -0.4375, 0.375}, -- NodeBox7
			{-0.0625, -0.5, -0.5, 0, -0.4375, 0.5}, -- NodeBox8
			{0, -0.5, -0.5, 0.0625, -0.4375, 0.5}, -- NodeBox9
			{0.0625, -0.5, -0.5, 0.125, -0.4375, 0.375}, -- NodeBox10
			{0.125, -0.5, -0.5, 0.1875, -0.4375, 0.25}, -- NodeBox11
			{0.1875, -0.5, -0.5, 0.25, -0.4375, 0.125}, -- NodeBox12
			{0.25, -0.5, -0.5, 0.3125, -0.4375, 0}, -- NodeBox13
			{0.3125, -0.5, -0.5, 0.375, -0.4375, -0.125}, -- NodeBox14
			{0.375, -0.5, -0.5, 0.4375, -0.4375, -0.25}, -- NodeBox15
			{0.4375, -0.5, -0.5, 0.5, -0.4375, -0.375}, -- NodeBox16
		}
	}
})

