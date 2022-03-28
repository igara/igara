import * as fs from "fs";
import highlight from "highlight.js";
import * as marked from "marked";

const highlightStyle = fs.readFileSync("./node_modules/highlight.js/styles/github.css", "utf8");
const markdownStyle = fs.readFileSync("./node_modules/github-markdown-css/github-markdown-light.css", "utf8");
const styleTag = `<style>
${highlightStyle}
${markdownStyle}
.markdown-body img {
  object-fit: contain;
  height: auto;
}
</style>`;

const exec = () => {
  const markdown = fs.readFileSync("README.md").toString();
  const renderer = new marked.Renderer();
  renderer.link = (href, _, text) => {
    if (/^#/.test(href)) return `<a href="${href}">${text}</a>`;

    return `<a target="_blank" rel="noopener noreferrer" href="${href}">${text}</a>`;
  };

  let body = marked.marked(markdown, {
    gfm: true,
    highlight: (code) => {
      return highlight.highlightAuto(code).value;
    },
    renderer,
  });

  body = `<div class="markdown-body">
  ${body}
</div>`;

  fs.writeFileSync("README.html", styleTag + body);
};

exec();
