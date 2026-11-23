package com.bucktrail.android.ui.forms

import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.border
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.selected
import androidx.compose.ui.unit.dp
import com.bucktrail.android.R
import com.bucktrail.android.data.CategoryEntity
import com.bucktrail.android.domain.Categories
import com.bucktrail.android.domain.CategoryEditing
import com.bucktrail.android.ui.categoryLabel
import com.bucktrail.android.ui.components.BarAction
import com.bucktrail.android.ui.components.BtAlert
import com.bucktrail.android.ui.components.GhostButton
import com.bucktrail.android.ui.components.PrimaryButton
import com.bucktrail.android.ui.components.RoundIconButton
import com.bucktrail.android.ui.components.SectionLabel
import com.bucktrail.android.ui.components.SfIcons
import com.bucktrail.android.ui.components.SheetPage
import com.bucktrail.android.ui.components.ThinDivider
import com.bucktrail.android.ui.theme.Bt
import com.bucktrail.android.ui.theme.Typo
import kotlinx.coroutines.launch

/** Selettore categoria (§4.3 `CategoryPickerView`): elenco con check, «Chiudi» e «Gestisci». */
@Composable
fun CategoryPickerSheet(categories: List<CategoryEntity>, selected: String?, onSelect: (String) -> Unit, onManage: () -> Unit, onClose: () -> Unit) {
    val c = Bt.colors
    SheetPage(
        stringResource(R.string.categoria), onClose,
        leading = { BarAction(stringResource(R.string.chiudi), onClose, Modifier.testTag("btn_closeCategoryPicker")) },
        trailing = { BarAction(stringResource(R.string.gestisci), onManage, Modifier.testTag("btn_manageCategories")) },
    ) {
        categories.forEachIndexed { i, cat ->
            if (i > 0) ThinDivider(Modifier.padding(horizontal = 20.dp), c.divider)
            Row(
                Modifier.fillMaxWidth().heightIn(min = 52.dp).testTag("categoryRow_${cat.name}").clickable(role = Role.Button) { onSelect(cat.name) }.padding(horizontal = 20.dp),
                verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(14.dp),
            ) {
                Icon(SfIcons.forName(cat.icon), null, tint = c.smoke, modifier = Modifier.size(18.dp))
                Text(categoryLabel(cat.name), style = Typo.formOption.copy(fontSize = androidx.compose.ui.unit.TextUnit(16f, androidx.compose.ui.unit.TextUnitType.Sp)), color = c.ink, modifier = Modifier.weight(1f))
                if (cat.name == selected) Icon(SfIcons.forName("checkmark"), null, tint = c.ink, modifier = Modifier.size(18.dp))
            }
        }
    }
}

/** Gestione categorie (§4.8): Predefinite e Personalizzate, aggiunta, modifica, eliminazione. */
@OptIn(ExperimentalFoundationApi::class)
@Composable
fun CategoryManagementSheet(
    categories: List<CategoryEntity>, usageCount: (String) -> Int,
    onSave: suspend (CategoryEntity?, String, String) -> Boolean, onDelete: (CategoryEntity) -> Unit, onClose: () -> Unit,
) {
    val c = Bt.colors
    var editing by remember { mutableStateOf<CategoryEntity?>(null) }
    var adding by rememberSaveable { mutableStateOf(false) }
    var toDelete by remember { mutableStateOf<CategoryEntity?>(null) }
    var defaultAlert by remember { mutableStateOf(false) }
    val defaults = categories.filter { it.isDefault }
    val custom = categories.filter { !it.isDefault }

    SheetPage(
        stringResource(R.string.categorie), onClose,
        leading = { RoundIconButtonPlain("chevron.left", stringResource(R.string.chiudi), onClose) },
        trailing = { RoundIconButtonPlain("plus", stringResource(R.string.nuova_categoria), { adding = true }, Modifier.testTag("btn_addCategory")) },
        largeTitle = true,
    ) {
        Column(Modifier.padding(horizontal = 20.dp, vertical = 8.dp), verticalArrangement = Arrangement.spacedBy(20.dp)) {
            Column {
                SectionLabel(stringResource(R.string.predefinite))
                defaults.forEachIndexed { i, cat ->
                    if (i > 0) ThinDivider(color = c.divider)
                    CategoryRowItem(cat, isDefault = true, onClick = { defaultAlert = true }, onLongClick = null)
                }
            }
            Column {
                SectionLabel(stringResource(R.string.personalizzate))
                if (custom.isEmpty()) Text(
                    stringResource(R.string.nessuna_categoria_personalizzata_premi_p), style = Typo.secondary, color = c.smoke,
                    modifier = Modifier.padding(vertical = 14.dp),
                )
                custom.forEachIndexed { i, cat ->
                    if (i > 0) ThinDivider(color = c.divider)
                    var menu by remember { mutableStateOf(false) }
                    Box {
                        CategoryRowItem(cat, isDefault = false, onClick = { editing = cat }, onLongClick = { menu = true })
                        DropdownMenu(menu, { menu = false }) {
                            DropdownMenuItem(text = { Text(stringResource(R.string.modifica)) }, onClick = { menu = false; editing = cat })
                            DropdownMenuItem(text = { Text(stringResource(R.string.elimina), color = c.danger) }, onClick = { menu = false; toDelete = cat })
                        }
                    }
                }
            }
        }
    }

    if (adding || editing != null) AddCategoryForm(
        editing, categories, onSave = { name, icon -> onSave(editing, name, icon) },
        onDelete = editing?.let { cat -> { toDelete = cat } }, onClose = { adding = false; editing = null },
    )
    if (defaultAlert) BtAlert(
        stringResource(R.string.categoria_predefinita), stringResource(R.string.le_categorie_predefinite_non_possono_ess),
        stringResource(R.string.chiudi), { defaultAlert = false }, { defaultAlert = false }, stringResource(R.string.annulla), destructive = false,
    )
    toDelete?.let { cat ->
        val count = usageCount(cat.name)
        BtAlert(
            stringResource(R.string.elimina_categoria_titolo, cat.name),
            when (CategoryEditing.deleteMessage(count)) {
                CategoryEditing.DeleteMessage.None -> stringResource(R.string.elimina_categoria_0)
                CategoryEditing.DeleteMessage.One -> stringResource(R.string.elimina_categoria_1)
                CategoryEditing.DeleteMessage.Many -> stringResource(R.string.elimina_categoria_n, count)
            },
            stringResource(R.string.elimina), { toDelete = null; if (editing?.id == cat.id) editing = null; onDelete(cat) }, { toDelete = null }, stringResource(R.string.annulla),
        )
    }
}

@Composable
private fun RoundIconButtonPlain(icon: String, description: String, onClick: () -> Unit, modifier: Modifier = Modifier) {
    // iOS: pulsanti circolari 44 con bordo `fog` (indietro, +); area toccabile 48
    val c = Bt.colors
    Box(modifier.size(48.dp).clickable(role = Role.Button, onClick = onClick).semantics { contentDescription = description }, contentAlignment = Alignment.Center) {
        Box(Modifier.size(44.dp).clip(CircleShape).background(c.surface).border(1.dp, c.fog, CircleShape), contentAlignment = Alignment.Center) {
            Icon(SfIcons.forName(icon), null, tint = c.ink, modifier = Modifier.size(22.dp))
        }
    }
}

@OptIn(ExperimentalFoundationApi::class)
@Composable
private fun CategoryRowItem(cat: CategoryEntity, isDefault: Boolean, onClick: () -> Unit, onLongClick: (() -> Unit)?) {
    val c = Bt.colors
    Row(
        Modifier.fillMaxWidth().heightIn(min = 56.dp).testTag("categoryManageRow_${cat.name}")
            .combinedClickable(role = Role.Button, onClick = onClick, onLongClick = onLongClick).padding(vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Box(Modifier.size(36.dp).clip(CircleShape).background(c.fog), contentAlignment = Alignment.Center) {
            Icon(SfIcons.forName(cat.icon), null, tint = c.smoke, modifier = Modifier.size(16.dp))
        }
        Text(categoryLabel(cat.name), style = Typo.formOption.copy(fontSize = androidx.compose.ui.unit.TextUnit(16f, androidx.compose.ui.unit.TextUnitType.Sp)), color = c.ink, modifier = Modifier.weight(1f))
        if (isDefault) Text(stringResource(R.string.predefinita), style = Typo.formOptionSub, color = c.smoke)
        else Icon(SfIcons.forName("chevron.right"), null, tint = c.smoke, modifier = Modifier.size(16.dp))
    }
}

/** Nuova / modifica categoria (§4.8): icona (griglia a 6 colonne), nome, avviso duplicato. */
@Composable
fun AddCategoryForm(
    editing: CategoryEntity?, all: List<CategoryEntity>, onSave: suspend (String, String) -> Boolean,
    onDelete: (() -> Unit)?, onClose: () -> Unit,
) {
    val c = Bt.colors
    val scope = rememberCoroutineScope()
    var name by rememberSaveable { mutableStateOf(editing?.name.orEmpty()) }
    var icon by rememberSaveable { mutableStateOf(editing?.icon ?: Categories.UNKNOWN_ICON) }
    var showGrid by rememberSaveable { mutableStateOf(false) }
    var saving by remember { mutableStateOf(false) }
    var failed by remember { mutableStateOf(false) }
    val duplicate = CategoryEditing.isDuplicate(name, all.map { it.id to it.name }, editing?.id)
    val valid = name.isNotBlank() && !duplicate

    FullScreenForm(onDismiss = { if (!saving) onClose() }, cancelTag = "btn_cancelAddCategory") {
        Text(stringResource(if (editing == null) R.string.nuova_categoria else R.string.modifica_categoria), style = Typo.sheetTitle, color = c.ink)
        Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
            SectionLabel(stringResource(R.string.icona))
            Row(Modifier.fillMaxWidth().heightIn(min = 48.dp).clickable(role = Role.Button) { showGrid = !showGrid }, verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                Box(Modifier.size(48.dp).clip(CircleShape).background(c.fog), contentAlignment = Alignment.Center) {
                    Icon(SfIcons.forName(icon), null, tint = c.ink, modifier = Modifier.size(20.dp))
                }
                Text(stringResource(R.string.cambia_icona), style = Typo.formOption, color = c.smoke, modifier = Modifier.weight(1f))
                Icon(SfIcons.forName(if (showGrid) "chevron.up" else "chevron.down"), null, tint = c.smoke, modifier = Modifier.size(16.dp))
            }
            if (showGrid) Column(Modifier.padding(top = 12.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Categories.availableIcons.chunked(6).forEach { rowIcons ->
                    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                        rowIcons.forEach { name ->
                            val sel = icon == name
                            Box(
                                Modifier.size(44.dp).clip(CircleShape).background(if (sel) c.ink else c.fog).clickable(role = Role.Button) { icon = name; showGrid = false }.semantics { contentDescription = name.replace('.', ' '); this.selected = sel },
                                contentAlignment = Alignment.Center,
                            ) { Icon(SfIcons.forName(name), null, tint = if (sel) c.paper else c.smoke, modifier = Modifier.size(18.dp)) }
                        }
                    }
                }
            }
            FieldLine()
        }
        Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
            SectionLabel(stringResource(R.string.nome))
            Box {
                if (name.isEmpty()) Text(stringResource(R.string.es_musica_sport_palestra), style = Typo.formDescription, color = c.smoke.copy(alpha = 0.45f))
                BasicTextField(name, { name = it.take(40) }, singleLine = true, textStyle = Typo.formDescription.copy(color = c.ink),
                    cursorBrush = SolidColor(c.accent), modifier = Modifier.fillMaxWidth().testTag("tf_categoryName"))
            }
            FieldLine()
            if (duplicate) Text(stringResource(R.string.categoria_esiste_gia), style = Typo.caption, color = c.smoke)
        }
        if (failed) Text(stringResource(R.string.save_failed), style = Typo.formOption, color = c.danger)
        Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
            PrimaryButton(stringResource(if (editing == null) R.string.salva else R.string.aggiorna), enabled = valid && !saving, modifier = Modifier.testTag("btn_saveCategory"), onClick = {
                saving = true; failed = false
                scope.launch {
                    val ok = onSave(name.trim(), icon)
                    saving = false
                    if (ok) onClose() else failed = true
                }
            })
            onDelete?.let { GhostButton(stringResource(R.string.elimina), it, Modifier.testTag("btn_deleteCategory")) }
        }
    }
}
