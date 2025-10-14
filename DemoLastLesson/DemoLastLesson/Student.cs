namespace DemoLastLesson;

public class Student
{
    public int Id { get; set; }
    public string Name { get; set; }

    public string Address { get; set; }

    public List<Exam> Exams { get; set; } = new List<Exam>();
}

