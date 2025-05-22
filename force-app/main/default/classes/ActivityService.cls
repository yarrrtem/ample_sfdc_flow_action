public class ActivityService {
    public static Task createSequenceTask(Id contactId, String sequenceId, String enrichStatus, String sequenceStatus) {
        Task t = new Task(
            Subject = 'Added to Amplemarket sequence ' + sequenceId,
            WhoId = contactId,
            Status = 'Completed',
            Description = 'Enrich status: ' + enrichStatus + ' | Sequence status: ' + sequenceStatus
        );
        
        insert t;
        return t;
    }
} 