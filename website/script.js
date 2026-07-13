const dialog = document.querySelector('#location-dialog');
const closeButton = document.querySelector('.close-button');

document.querySelectorAll('.location-trigger').forEach((button) => {
  button.addEventListener('click', () => dialog.showModal());
});

closeButton.addEventListener('click', () => dialog.close());

dialog.addEventListener('click', (event) => {
  if (event.target === dialog) dialog.close();
});
