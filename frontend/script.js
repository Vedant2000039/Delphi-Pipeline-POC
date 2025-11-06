document.getElementById('fetch-btn').addEventListener('click', async () => {
  try {
    const res = await fetch('/');
    const data = await res.json();
    document.getElementById('env').innerText = data.environment;
    document.getElementById('response').innerText = JSON.stringify(data, null, 2);
  } catch (err) {
    document.getElementById('response').innerText = 'Error fetching backend: ' + err;
  }
});
