
def escape_filename(name)
	name.gsub(/[^\w\-_\.'\(\)]/, '_')
end