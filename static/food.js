document.addEventListener('DOMContentLoaded', () => {
  const grid = document.querySelector('.food-calendar');
  const preview = document.querySelector('.food-preview');
  const image = preview && preview.querySelector('img');
  if (!grid || !preview || !image) return;

  const offset = 18;
  const show = (link, event) => {
    image.src = link.dataset.previewSrc;
    image.alt = link.dataset.previewAlt || '';
    const w = Number(link.dataset.previewWidth || 0);
    const h = Number(link.dataset.previewHeight || 0);
    preview.style.setProperty('--preview-aspect-ratio',
      w > 0 && h > 0 ? `${w} / ${h}` : '1 / 1');
    preview.classList.add('is-visible');
    preview.setAttribute('aria-hidden', 'false');
    if (event) move(event);
  };
  const move = (event) => {
    preview.style.left = `${event.clientX + offset}px`;
    preview.style.top = `${event.clientY + offset}px`;
  };
  const hide = () => {
    preview.classList.remove('is-visible');
    preview.setAttribute('aria-hidden', 'true');
    image.removeAttribute('src');
    image.alt = '';
  };

  grid.addEventListener('mouseover', (event) => {
    const link = event.target.closest('.food-entry-link[data-preview-src]');
    if (link) show(link, event);
  });
  grid.addEventListener('mousemove', (event) => {
    if (preview.classList.contains('is-visible')) move(event);
  });
  grid.addEventListener('mouseout', (event) => {
    const link = event.target.closest('.food-entry-link[data-preview-src]');
    if (!link) return;
    if (event.relatedTarget instanceof Node && link.contains(event.relatedTarget)) return;
    hide();
  });
  grid.addEventListener('focusin', (event) => {
    const link = event.target.closest('.food-entry-link[data-preview-src]');
    if (link) show(link, null);
  });
  grid.addEventListener('focusout', hide);
});
