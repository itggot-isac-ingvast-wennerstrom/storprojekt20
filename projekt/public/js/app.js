const create_comment_a = document.getElementById('create_comment_fold');
const create_comment_form = document.querySelector(
	'.post_show .create_comment'
);

const edit_comment_links = document.querySelectorAll('.comment_edit');
const edit_comment_forms = document.querySelectorAll('.update_comment_form');
create_comment_form.style.display = 'none';

create_comment_a.addEventListener('click', function() {
	if (create_comment_form.style.display === 'none') {
		create_comment_form.style.display = 'flex';
		create_comment_a.innerHTML = 'Hide create a comment';
	} else {
		create_comment_a.innerHTML = 'Create a comment';
		create_comment_form.style.display = 'none';
	}
});

for (let index = 0; index < edit_comment_links.length; index++) {
	edit_comment_forms[index].style.display = 'none';
	edit_comment_links[index].addEventListener('click', function() {
		if (edit_comment_forms[index].style.display === 'none') {
			edit_comment_forms[index].style.display = 'flex';
			edit_comment_links[index].innerHTML = 'Cancel';
		} else {
			edit_comment_links[index].innerHTML = 'Edit comment';
			edit_comment_forms[index].style.display = 'none';
		}
	});
}
