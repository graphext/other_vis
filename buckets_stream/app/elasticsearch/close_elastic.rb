def close_elastic(elastic_pid)
	$stdout.write "Closing elasticsearch... "
	Process.kill("INT", elastic_pid)
	Process.wait(elastic_pid)
	puts "OK"
end