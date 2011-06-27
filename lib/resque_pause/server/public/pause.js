jQuery(document).ready(function($) {
	$('input:checkbox.pause').click( function(){
		var queue = $(this);
		var data = {'queue_name': queue.val()};
		var url = queue.is(':checked') ? '/pause' : '/unpause';
		$.ajax({
		  type: 'POST',
		  url: url,
		  data: data,
		  async: false,
		  cache: false,
		  success: function() { return true; },
		  error: function() { return false; },
		  dataType: 'json'
		});

	});
});
