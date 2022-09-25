import * as fs from "fs";
import * as marked from "marked";

const exec = () => {
  const markdown = fs.readFileSync("README.md").toString();
  const renderer = new marked.Renderer();
  renderer.link = (href, _, text) => {
    if (/^#/.test(href)) return `<a href="${href}">${text}</a>`;

    return `<a target="_blank" rel="noopener noreferrer" href="${href}">${text}</a>`;
  };

  let body = marked.marked(markdown, {
    gfm: true,
    renderer,
  });

  body = `<div class="markdown-body">
  ${body}
</div>`;

  fs.writeFileSync("README.html", body);
};

exec();
