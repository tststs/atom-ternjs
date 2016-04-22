"use babel";

const tags = {

  '&': '&amp;',
  '<': '&lt;',
  '>': '&gt;'
};

export function replaceTag(tag) {

  return tags[tag];
}

export function replaceTags(str) {

  if (!str) {

    return '';
  }

  return str.replace(/[&<>]/g, replaceTag);
}
