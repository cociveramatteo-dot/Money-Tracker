package com.bucktrail.android.sync

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class SyncBaselineTest {
    @Test fun plansAllFiveCasesForIncrementalAndFullUpserts() {
        val local = setOf("deletedElsewhere", "newLocal", "sharedDirty", "sharedClean")
        val remote = setOf("deletedHere", "newRemote", "sharedDirty", "sharedClean")
        val base = setOf("deletedHere", "deletedElsewhere", "sharedDirty", "sharedClean")
        val dirty = setOf("deletedElsewhere", "sharedDirty")

        for (fullUpsert in listOf(false, true)) {
            val plan = SyncBaseline.plan(local, remote, base, dirty, fullUpsert)
            val uploads = setOf("newLocal", "sharedDirty")
            assertEquals(if (fullUpsert) uploads + "sharedClean" else uploads, plan.upload)
            assertEquals(setOf("deletedHere"), plan.deleteRemote)
            assertEquals(setOf("deletedElsewhere"), plan.deletedElsewhere)
            assertEquals(setOf("newLocal", "sharedDirty", "sharedClean"), plan.newBase)
        }
    }

    @Test fun missingBaselineOnlyUploadsDirtyTransactionsOrAllOtherRows() {
        val local = setOf("localDirty", "localClean", "common")
        val remote = setOf("common", "newRemote")
        val dirty = setOf("localDirty")
        for (fullUpsert in listOf(false, true)) {
            val plan = SyncBaseline.plan(local, remote, null, dirty, fullUpsert)
            assertEquals(if (fullUpsert) local else dirty, plan.upload)
            assertTrue(plan.deleteRemote.isEmpty())
            assertTrue(plan.deletedElsewhere.isEmpty())
            assertEquals((local intersect remote) + plan.upload, plan.newBase)
        }
    }
}
