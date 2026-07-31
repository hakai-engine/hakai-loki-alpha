package database

import (
	"context"
	"crypto/sha256"
	"database/sql/driver"
	"encoding/hex"
	"errors"
	"regexp"
	"testing"

	"github.com/DATA-DOG/go-sqlmock"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

type capturedString struct {
	value string
}

func (capture *capturedString) Match(value driver.Value) bool {
	text, ok := value.(string)
	if ok {
		capture.value = text
	}
	return ok
}

func TestHakaiCreateSessionPersistsOpaqueHashAndPrunesExpiredRows(t *testing.T) {
	db, mock, err := sqlmock.New()
	require.NoError(t, err)
	defer db.Close()

	storedHash := &capturedString{}
	mock.ExpectBegin()
	mock.ExpectExec(regexp.QuoteMeta("DELETE FROM `account_sessions` WHERE `expires` <= ?")).
		WithArgs(sqlmock.AnyArg()).
		WillReturnResult(sqlmock.NewResult(0, 2))
	mock.ExpectExec(regexp.QuoteMeta("INSERT INTO `account_sessions` (`id`, `account_id`, `expires`) VALUES (?, ?, ?)")).
		WithArgs(storedHash, uint32(42), sqlmock.AnyArg()).
		WillReturnResult(sqlmock.NewResult(1, 1))
	mock.ExpectCommit()

	token, err := (&Account{ID: 42}).CreateSession(context.Background(), db)

	require.NoError(t, err)
	assert.Regexp(t, `^[0-9a-f]{64}$`, token)
	raw, decodeErr := hex.DecodeString(token)
	require.NoError(t, decodeErr)
	assert.Len(t, raw, 32)
	expectedHash := sha256.Sum256([]byte(token))
	assert.Equal(t, hex.EncodeToString(expectedHash[:]), storedHash.value)
	assert.NoError(t, mock.ExpectationsWereMet())
}

func TestHakaiCreateSessionRollsBackWhenPruneFails(t *testing.T) {
	db, mock, err := sqlmock.New()
	require.NoError(t, err)
	defer db.Close()

	mock.ExpectBegin()
	mock.ExpectExec(regexp.QuoteMeta("DELETE FROM `account_sessions` WHERE `expires` <= ?")).
		WithArgs(sqlmock.AnyArg()).
		WillReturnError(errors.New("prune failed"))
	mock.ExpectRollback()

	_, err = (&Account{ID: 42}).CreateSession(context.Background(), db)

	assert.Error(t, err)
	assert.NoError(t, mock.ExpectationsWereMet())
}

func TestHakaiCreateSessionRollsBackWhenInsertFails(t *testing.T) {
	db, mock, err := sqlmock.New()
	require.NoError(t, err)
	defer db.Close()

	mock.ExpectBegin()
	mock.ExpectExec(regexp.QuoteMeta("DELETE FROM `account_sessions` WHERE `expires` <= ?")).
		WithArgs(sqlmock.AnyArg()).
		WillReturnResult(sqlmock.NewResult(0, 0))
	mock.ExpectExec(regexp.QuoteMeta("INSERT INTO `account_sessions` (`id`, `account_id`, `expires`) VALUES (?, ?, ?)")).
		WithArgs(sqlmock.AnyArg(), uint32(42), sqlmock.AnyArg()).
		WillReturnError(errors.New("insert failed"))
	mock.ExpectRollback()

	_, err = (&Account{ID: 42}).CreateSession(context.Background(), db)

	assert.Error(t, err)
	assert.NoError(t, mock.ExpectationsWereMet())
}
