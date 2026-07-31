package database

import (
	"regexp"
	"testing"

	"github.com/DATA-DOG/go-sqlmock"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestHakaiLoadPlayersFiltersCharacterListToTrainerVocation(t *testing.T) {
	db, mock, err := sqlmock.New()
	require.NoError(t, err)
	defer db.Close()

	const statement = `SELECT name, level, sex, vocation, looktype, lookhead, lookbody, looklegs,
		lookfeet, lookaddons, lastlogin
		FROM players
		WHERE account_id = ? AND vocation = ?`
	rows := sqlmock.NewRows([]string{
		"name", "level", "sex", "vocation", "looktype", "lookhead", "lookbody",
		"looklegs", "lookfeet", "lookaddons", "lastlogin",
	}).AddRow("Hakai Trainer", 1, 0, hakaiTrainerVocationID, 128, 0, 0, 0, 0, 0, 123)

	mock.ExpectQuery(regexp.QuoteMeta(statement)).
		WithArgs(uint32(42), hakaiTrainerVocationID).
		WillReturnRows(rows)

	account := &Account{ID: 42}
	players, err := LoadPlayers(db, account)

	require.NoError(t, err)
	require.Len(t, players, 1)
	assert.Equal(t, "Hakai Trainer", players[0].Info.Name)
	assert.Equal(t, uint32(123), account.LastLogin)
	assert.NoError(t, mock.ExpectationsWereMet())
}
