![images](/images/HashiCorp_Terraform.png)

# 1- Definition and Introduction 

| **What is Terraform?** | **ما هو تيرافورم؟** |
| :--- | :--- |
| Terraform is an open-source "Infrastructure as Code" (IaC) software tool created by HashiCorp. It enables developers and operations teams to define, provision, and manage cloud and on-premises infrastructure (such as virtual machines, networks, databases, and storage) safely and predictably using a simple, declarative configuration language known as **HCL (HashiCorp Configuration Language)**. | تيرافورم هي أداة برمجية مفتوحة المصدر لإدارة "البنية التحتية ككود" تم تطويرها بواسطة شركة هاشيكورب. تسمح لفرق التطوير والعمليات بإنشاء، وتعديل، وإدارة البنية التحتية لتكنولوجيا المعلومات (مثل الخوادم الافتراضية، الشبكات، قواعد البيانات، والتخزين) بطريقة آمنة وقابلة للتنبؤ باستخدام لغة تكوين وصفية بسيطة تُعرف باسم **إتش سي إل**. |
| **Key Features of Terraform:** | **:الميزات الرئيسية لـ تيرافورم** |
| **1- Multi-Cloud Support:** Terraform is not tied to a single cloud provider. It supports major cloud platforms like AWS, Microsoft Azure, and Google Cloud, as well as on-premises and container environments like VMware and Kubernetes. | 1- دعم متعدد السحاب: لا تقتصر تيرافورم على مزود سحابي واحد، بل تدعم أشهر المنصات السحابية مثل أيه دبليو إس(أمازون)، مايكروسوفت أزور، وجوجل كلاود، بالإضافة إلى البيئات المحلية وبيئات الحاويات مثل فيمير وكوبرنيتس. |
| **2- State Management:** It maintains a state file that maps your configuration files to your real-world infrastructure, allowing you to track resource changes efficiently and accurately. | 2- إدارة الحالة: تحتفظ الأداة بملف حالة يربط ملفات التكوين الخاصة بك بالبنية التحتية الواقعية، مما يتيح لك تتبع تغييرات الموارد بكفاءة ودقة. |
| **3- Execution Plans:** Terraform generates an execution plan showing what it will do (create, update, or destroy) before executing the changes, minimizing deployment errors. | 3- خطط التنفيذ: تنشئ تيرافورم خطة تنفيذ توضح ما ستفعله (إنشاء، تحديث، أو حذف) قبل تنفيذ التغييرات فعلياً، مما يقلل من أخطاء النشر. |
| **4- Modularity and Reusability:** It allows users to create reusable "Modules" to provision complex infrastructure environments consistently across different projects and environments. | 4- النمطية وإعادة الاستخدام: تسمح للمستخدمين بإنشاء "وحدات" قابلة لإعادة الاستخدام لتوفير بيئات بنية تحتية معقدة بشكل متسق عبر مختلف المشاريع والبيئات. |

Imagine you are playing a city-building game. Usually, you build your city by clicking and placing one building at a time. It’s fun, but it’s hard to remember exactly how you built it, so you could never build the exact same city twice. Terraform is like a 'planning office' for computer infrastructure

![](/images/Screenshot%202026-10-31%20203720.png)

[What is Terraform in 3 Minutes (2026) | Terraform Tutorial for Beginners](https://youtu.be/vIROhFhJghw?si=E4yuYCQoGVjZOnvr)

![](/images/Screenshot%202026-10-31%20203148.png)

[Terraform in 5 Minutes (Explained Clearly)](https://youtu.be/7S9HKPwfxDM?si=oGkV3eOz09XCjJIC)
































# Terraform

**الهدف:** أتمتة بناء البنية التحتية على AWS بدل إنشائها يدوياً
**التكلفة:** المصادر التالية مجانية

## مصادر مجانية (اختر واحد)
- **الخيار الأول:** Terraform Course - Automate your AWS Cloud Infrastructure
- **الخيار الثاني:** AWS Terraform Full course - #30daysofAWSterraform

## مصدر إضافي
- [HashiCorp Terraform Tutorials](https://developer.hashicorp.com/terraform/tutorials) - الدروس الرسمية من الشركة المطورة

## تنبيه مهم
أي خدمة تُنشأ على AWS قد تسبب تكلفة إذا تُركت شغالة. بعد كل تجربة، نفّذ الأمر `terraform destroy` لحذف كل ما أنشأته.

## مطلوب
- روابط الكورسين أعلاه
