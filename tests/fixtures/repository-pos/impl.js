// SMELL: the service function reaches straight into a data store, building a
// query inline. Persistence and business logic are entangled. Candidate for
// extracting a Repository.
const DB = {
  users: [
    { id: 1, name: "Ada", active: true },
    { id: 2, name: "Lin", active: false },
  ],
};

function getActiveUserName(id) {
  // inline "query"
  const row = DB.users.filter((u) => u.id === id && u.active === true)[0];
  if (!row) return null;
  return row.name.toUpperCase();
}

module.exports = { getActiveUserName };
