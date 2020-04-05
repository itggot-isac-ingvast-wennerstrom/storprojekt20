const create_comment_a = document.getElementById('create_comment_fold');
const create_comment_form = document.querySelector(
	'.post_show .create_comment'
);

//create_comment_form.style.display = 'none';

create_comment_a.addEventListener('click', function() {
	if (create_comment_form.style.display === 'none') {
		create_comment_form.style.display = 'flex';
		create_comment_a.innerHTML = 'Hide create a comment';
	} else {
		create_comment_a.innerHTML = 'Create a comment';
		create_comment_form.style.display = 'none';
	}
});
