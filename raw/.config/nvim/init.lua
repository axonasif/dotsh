-- Scroll only one line for mouse wheel events to get smooth scrolling on touch screens
vim.cmd([[
	set mouse=a
	map <ScrollWheelUp> <C-Y>
	imap <ScrollWheelUp> <C-X><C-Y>
	map <ScrollWheelDown> <C-E>
	imap <ScrollWheelDown> <C-X><C-E>
]])
