'use babel';

export const messages = {

  noURI: 'No URI found for the given editor.'
};

function handleReject(type, message) {

  console[type] && console[type](`atom-ternjs: ${message}`);
}

export default {

  handleReject
};
