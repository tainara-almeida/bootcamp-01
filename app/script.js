// app/script.js
document.getElementById('birthday-form').addEventListener('submit', function (event) {
    event.preventDefault();

    // Em uma aplicação real, aqui você faria uma chamada a um backend
    // que publicaria a mensagem no Pub/Sub.
    // Para esta demo, apenas mostramos uma confirmação.

    const form = document.getElementById('birthday-form');
    const confirmation = document.getElementById('confirmation');

    form.classList.add('hidden');
    confirmation.classList.remove('hidden');
});
