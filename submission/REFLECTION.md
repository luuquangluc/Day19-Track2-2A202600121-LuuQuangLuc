# Reflection — Lab 19

**Tên:** Lưu Quang Lực
**Cohort:** A20-K1
**Path đã chạy:** lite

---

## Câu hỏi (≤ 200 chữ)

> Trên golden set 50 queries, mode nào thắng ở loại query nào (`exact` /
> `paraphrase` / `mixed`), và tại sao? Khi nào bạn **không** dùng hybrid
> (i.e. khi nào pure BM25 hoặc pure vector là lựa chọn đúng)?

Trả lời: 
- **Exact mode:** Thường thắng ở các query chứa từ khóa đặc thù (mã số, tên riêng chính xác). BM25 chiếm ưu thế vì nó khớp chính xác từng ký tự, trong khi vector đôi khi bị "nhiễu" bởi các từ có ngữ nghĩa gần giống nhưng không phải thực thể cần tìm.
- **Paraphrase mode:** Semantic (Vector) thắng rõ rệt. Vì người dùng dùng từ đồng nghĩa hoặc cách diễn đạt khác, BM25 bị lỗi "vocabulary mismatch", trong khi vector search hiểu được ngữ cảnh.
- **Mixed mode:** Hybrid thắng tuyệt đối nhờ thuật toán RRF kết hợp được cả hai tín hiệu: vừa khớp từ khóa quan trọng, vừa đảm bảo đúng chủ đề ngữ nghĩa.

**Tại sao Hybrid thắng?** RRF (Reciprocal Rank Fusion) giúp đưa các kết quả đứng đầu của cả hai phương pháp lên trên. Nó lấy điểm mạnh của keyword (độ chính xác cao với thực thể) bù cho semantic (hiểu ý nghĩa tổng quát) và ngược lại.

**Khi nào KHÔNG dùng hybrid?**
- Dùng **Pure BM25** khi: Cần độ trễ cực thấp (không tốn thời gian embed), RAM hạn chế, hoặc hệ thống chỉ phục vụ tra cứu mã (SKU, ID, error code).
- Dùng **Pure Vector** khi: Dữ liệu đa phương tiện (ảnh, âm thanh) hoặc khi query mang tính cảm xúc/gợi ý hơn là tìm sự kiện cụ thể.


## Điều ngạc nhiên nhất khi làm lab này

Đáng ngạc nhiên là sự khác biệt về chất lượng giữa BM25 thuần và Vector thuần ở mode Exact. Mình kỳ vọng BM25 sẽ "nhỉnh" hơn chút, nhưng thực tế nó lại loại bỏ hoàn toàn các kết quả gần đúng về mặt ý nghĩa, trong khi Vector lại hay bị nhầm lẫn với các từ đồng nghĩa. Điều này cho thấy sự đánh đổi rõ rệt giữa "chính xác tuyệt đối" và "hiểu ngữ nghĩa" trong Search.

---
