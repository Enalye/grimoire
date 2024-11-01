/** 
 * Droits d’auteur: Enalye
 * Licence: Zlib
 * Auteur: Enalye
 */
module grimoire.library.task;

import grimoire;

void grLoadStdLibTask(GrModule library) {
    library.setModule("task");

    library.setModuleInfo(GrLocale.fr_FR, "Fonctions relatives à la gestion des tâches.");
    library.setModuleInfo(GrLocale.en_US, "Functions to help task handling.");

    library.setDescription(GrLocale.fr_FR, "Tue la tâche indiquée.");
    library.setDescription(GrLocale.en_US, "Kill the specified task.");
    library.setParameters(["instance"]);
    library.addFunction(&_kill, "kill", [grInstance]);

    library.setDescription(GrLocale.fr_FR, "Tue les tâches indiquées.");
    library.setDescription(GrLocale.en_US, "Kill the specified tasks.");
    library.setParameters(["instances"]);
    library.addFunction(&_kill_list, "kill", [grList(grInstance)]);

    library.setDescription(GrLocale.fr_FR, "Vérifie si la tâche a été tuée.");
    library.setDescription(GrLocale.en_US, "Check if the task has been killed.");
    library.setParameters(["instance"]);
    library.addFunction(&_isKilled, "isKilled", [grInstance], [grBool]);

    library.setDescription(GrLocale.fr_FR, "Vérifie si la tâche a été mis en pause.");
    library.setDescription(GrLocale.en_US, "Check if the task has been paused.");
    library.setParameters(["instance"]);
    library.addFunction(&_isSuspended, "isSuspended", [grInstance], [grBool]);
}

private void _kill(GrCall call) {
    call.getTask(0).kill();
}

private void _kill_list(GrCall call) {
    foreach (task; call.getList(0).getTasks()) {
        task.kill();
    }
}

private void _isKilled(GrCall call) {
    call.setBool(call.getTask(0).isKilled);
}

private void _isSuspended(GrCall call) {
    GrTask task = call.getTask(0);
    call.setBool(task.isLocked || task.blocker);
}
