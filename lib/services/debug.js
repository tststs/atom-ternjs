'use babel';

export const messages = {

  noURI: 'No URI found for the given editor.'
};

function getMessage(error) {

  return typeof error === 'string' ? error : error.message || 'Unknown error';
}

function handleCatch(error) {

  if (!error) {

    return;
  }

  const message = getMessage(error);
  const type = error.type || 'warn';

  console[type] && console[type](`atom-ternjs: ${message}`);
}

function handleCatchWithNotification(error) {

  const message = getMessage(error);

  handleCatch(error);
  atom.notifications.addWarning(message);
}

export default {

  handleCatchWithNotification,
  handleCatch
};
