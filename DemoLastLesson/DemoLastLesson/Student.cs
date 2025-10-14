namespace DemoLastLesson;

public class Student
{
    public int Id { get; set; }
    public string Name { get; set; }

    public Address Address { get; set; } = new();

    public List<Exam> Exams { get; set; } = new List<Exam>();
    public DateTime BirthDate { get; set; }
    public string Email { get; set; }
}
public class Address
{
    public string Street { get; set; }
    public string City { get; set; }
    public string State { get; set; }
    public string ZipCode { get; set; }
    public int Id { get; set; }
}

